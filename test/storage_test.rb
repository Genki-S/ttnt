require 'test_helper'
require 'ttnt/storage'

class StorageTest < TTNT::TestCase
  def setup
    @storage_file = "#{@repo.workdir}/.ttnt"
    FileUtils.rm_rf(@storage_file)

    @section = 'test'
    @storage = TTNT::Storage.new(@repo)
    @data = { 'a' => 1, 'b' => 2 }
  end

  def test_read_storage
    File.write(@storage_file, { @section => @data }.to_json)
    assert_equal @data, @storage.read(@section)
  end

  def test_read_storage_from_history
    @storage.write!(@section, @data)
    git_commit_am('Add data to storage file')
    sha = @repo.head.target_id
    new_data = { 'c' => 3 }
    @storage.write!(@section, new_data) # write to a file in working tree
    history_storage = TTNT::Storage.new(@repo, sha)
    assert_equal @data, history_storage.read(@section)
  end

  def test_write_storage
    @storage.write!(@section, @data)
    assert File.exist?(@storage_file), 'Storage file should be created.'
    assert_equal @data, JSON.parse(File.read(@storage_file))[@section]
  end

  def test_cannot_write_to_history_storage
    sha = @repo.head.target_id
    history_storage = TTNT::Storage.new(@repo, sha)
    assert_raises { history_storage.write!(@section, @data) }
  end
end
