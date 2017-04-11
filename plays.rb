# Demonstration of SQL and Object Relational Mapping--in which we use Ruby code to carry out SQL queries.

require 'sqlite3'
require 'singleton'

# pulls database into Ruby file and ensures there is only one instance of that database
class PlayDBConnection < SQLite3::Database
  include Singleton
  def initialize
    super('plays.db')
    self.type_translation = true # type_translation makes sure the data we get back is the same data type as the data passed into the db
    self.results_as_hash = true # data comes back as a hash (instead of a 2D array)
  end
end


class Play
  attr_accessor :title, :year, :playwright_id

  def self.all
    data = PlayDBConnection.instance.execute("SELECT * FROM plays") # returns array of hashes, where each hash represents a row of the database
    # implment ORM aspect:
    data.map { |datum| Play.new(datum) }
  end

  def initialize(options)  #options argument is an options hash
    @id = options['id']  # unpack and pull variables out of options hash
    # id will either be defined already in data in self.all method above, or could be nil if doesn't exist yet
    @title = options['title']
    @year = options['year']
    @playwright_id = options['playwright_id']
    # now every instance of Play that we have will have the above 4 instance variables
  end

  # allows user to call #create on the instance and save the instance to the database
  def create
    raise "#{self} already in database" if @id
    PlayDBConnection.instance.execute(<<-SQL,@title, @year, @playwright_id)
      INSERT INTO
        plays (title, year, playwright_id)
      VALUES
        (?, ?, ?)
    SQL
    # each ? represents an instance variable that is passed in; use ? instead of the acutal var name to prevent * SQL injection attacks *
    # defines the id and saves it to database
    @id = PlayDBConnection.instance.last_insert_row_id # gets the ID of the last row and insert it into the database
  end

  def update
    raise "#{self} not in database" unless @id
    PlayDBConnection.instance.execute(<<-SQL, @title, @year, @playwright_id, @id)
      UPDATE
        plays
      SET
        title = ?, year = ?, playwright_id = ?
      WHERE
        id = ?
    SQL
  end


end
