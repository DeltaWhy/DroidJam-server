#!/usr/bin/env ruby
require 'midilib'
require 'midilib/io/seqreader'
require 'midilib/io/seqwriter'

out_filename = ARGV.delete_at(0)
in_filenames = ARGV

out_seq = MIDI::Sequence.new()
in_filenames.each do |fn|
  File.open(fn, 'rb') do |file|
    seq = MIDI::Sequence.new()
    seq.read(file) do |track, num_tracks, i|
      puts "read track #{i} of #{num_tracks}"
    end
    seq.each {|track| out_seq.tracks << track}
  end
end

File.open(out_filename, 'wb') do |file|
  out_seq.write(file)
end
