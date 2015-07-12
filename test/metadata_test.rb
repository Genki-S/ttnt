require 'test_helper'
require 'ttnt/metadata'

class MetaDataTest < TTNT::TestCase
  def setup
    @storage_file = "#{@repo.workdir}/.ttnt"
    File.delete(@storage_file)

    @metadata = TTNT::MetaData.new(@repo, nil)
    @name = 'anchored_sha'
    @value = 'abcdef'
  end

  def test_get_metadata
    File.write(@storage_file, { 'meta' => { @name => @value} }.to_json)
    assert @metadata.get(@name).nil?, '#get should not read from file.'
    @metadata.read!
    assert_equal @value, @metadata.get(@name)
  end

  def test_write_metadata
    @metadata.set(@name, @value)
    @metadata.write!
    expected = { 'meta' => { @name => @value } }
    assert_equal expected, JSON.parse(File.read(@storage_file))
  end
end
