require "gcloud/datastore"

class Driver
  include ActiveModel::Model
  include ActiveModel::Validations

  attr_accessor :id, :fist_name, :last_name, :cellphone, :email, :ine_image, :driver_license_image,
                :avatar_image, :car_license_image, :insurance_policy_image,
                :car_plates_images, :driver_clabe, :diver_bank, :phone_uuid, :member_since

  validates :id, :fist_name, :last_name, :cellphone, :email true

  def self.dataset
    @dataset ||= Google::Cloud::Datastore.new(
      project: Rails.application.config.
                     database_configuration[Rails.env]["dataset_id"]
    )
  end

  # Query Driver entities from Cloud Datastore.
  #
  # returns an array of Driver query results and a cursor
  # that can be used to query for additional results.
  # [START drivers_by_creator]
  def self.query options = {}
    query = Google::Cloud::Datastore::Query.new
    query.kind "Driver"
    query.limit options[:limit]   if options[:limit]
    query.cursor options[:cursor] if options[:cursor]

    if options[:creator_id]
      query.where "creator_id", "=", options[:creator_id]
    end
    # [END drivers_by_creator]

    results = dataset.run query
    drivers   = results.map {|entity| Driver.from_entity entity }

    if options[:limit] && results.size == options[:limit]
      next_cursor = results.cursor
    end

    return drivers, next_cursor
  end

  def self.from_entity entity
    driver = Driver.new
    driver.id = entity.key.id
    entity.properties.to_hash.each do |name, value|
      driver.send "#{name}=", value if driver.respond_to? "#{name}="
    end
    driver
  end

  # Lookup Driver by ID.  Returns Driver or nil.
  def self.find id
    query    = Google::Cloud::Datastore::Key.new "Driver", id.to_i
    entities = dataset.lookup query

    from_entity entities.first if entities.any?
  end

  # alias "find_by_id" for compatibility with Active Record
  singleton_class.send(:alias_method, :find_by_id, :find)

  def to_entity
    entity = Google::Cloud::Datastore::Entity.new
    entity.key = Google::Cloud::Datastore::Key.new "Driver", id
    entity["title"]        = title
    entity["author"]       = author               if author.present?
    entity["published_on"] = published_on.to_time if published_on.present?
    entity["description"]  = description          if description.present?
    entity["image_url"]    = image_url            if image_url.present?
    entity["creator_id"]   = creator_id           if creator_id.present?
    entity
  end

  def update attributes
    attributes.each do |name, value|
      send "#{name}=", value
    end
    save
  end

  def destroy
    delete_image if image_url.present?

    Driver.dataset.delete Google::Cloud::Datastore::Key.new "Driver", id
  end

  def persisted?
    id.present?
  end

  def upload_image
    image = StorageBucket.files.new(
      key: "cover_images/#{id}/#{cover_image.original_filename}",
      body: cover_image.read,
      public: true
    )

    image.save

    self.image_url = image.public_url

    Driver.dataset.save to_entity
  end

  def delete_image
    bucket_name = StorageBucket.key
    image_uri   = URI.parse image_url

    if image_uri.host == "#{bucket_name}.storage.googleapis.com"
      # Remove leading forward slash from image path
      # The result will be the image key, eg. "cover_images/:id/:filename"
      image_key = image_uri.path.sub("/", "")
      image     = StorageBucket.files.new key: image_key

      image.destroy
    end
  end

  def update_image
    delete_image if image_url.present?
    upload_image
  end

  # [START enqueue_job]
  include GlobalID::Identification

  def save
    if valid?
      entity = to_entity
      Driver.dataset.save entity

      # TODO separate create and save ...
      unless persisted? # just saved
        self.id = entity.key.id
        lookup_driver_details
      end

      self.id = entity.key.id
      update_image if cover_image.present?
      true
    else
      false
    end
  end

  private

  def lookup_driver_details
    if [author, description, published_on, image_url].any? {|attr| attr.blank? }
      LookupDriverDetailsJob.perform_later self
    end
  end
  # [END enqueue_job]
end
