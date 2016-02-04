#
# Copyright 2016, Noah Kantrowitz
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'fileutils'
require 'json'

require 'erubis'
require 'mixlib/shellout'
require 'oily_png'



INPUT_FILE = '/Users/coderanger/Library/Mobile Documents/com~apple~Keynote/Documents/yolover.key'
ROOT = File.expand_path('..', __FILE__)

task 'extract' do
  FileUtils.mkdir_p(File.join(ROOT, 'build'))
  cmd = Mixlib::ShellOut.new(['osascript', File.join(ROOT, 'extract.applescript'), INPUT_FILE, ROOT])
  #cmd.run_command
  #cmd.error!
end

task 'images' => %w{extract} do
  img_path = File.join(ROOT, 'img')
  FileUtils.mkdir_p(img_path)
  Dir[File.join(ROOT, 'build', 'images', '*.png')].each do |path|
    raise "wat" unless File.basename(path) =~ /^images\.(\d{3})\.png$/
    FileUtils.copy(path, File.join(img_path, "#{$1.to_i}.png"))
  end
end

task 'sprites' => %w{extract} do
  FileUtils.mkdir_p(File.join(ROOT, 'build', 'thumbnails'))
  sprites = [[]]
  # Generate all thumbnails.
  Dir[File.join(ROOT, 'build', 'images', '*.png')].each do |path|
    puts "Generating thumbnail for #{File.basename(path)}"
    image = ChunkyPNG::Image.from_file(path)
    aspect_ratio = image.width.to_f / image.height.to_f
    # Cut the width in half.
    image.resample_bilinear!(512, (512/aspect_ratio).to_i)
    image.save(File.join(ROOT, 'build', 'thumbnails', File.basename(path)))
    # Batch up sprite sheets in groups of 10.
    if sprites.last.size < 10
      sprites.last << image
    else
      sprites << [image]
    end
  end
  # Generate sprite sheets.
  sprite_data = []
  sprites.each_with_index do |sheet_images, sheet_num|
    puts "Generating sprite sheet #{sheet_num}"
    sheet = ChunkyPNG::Image.new(sheet_images.first.width, sheet_images.reduce(0) {|total, i| total+i.height })
    sheet_images.each_with_index do |i, n|
      sheet.compose!(i, 0, n*i.height)
      sprite_data << {sheet: sheet_num, offset: n*i.height}
    end
    sheet.save(File.join(ROOT, 'img', "sprite-#{sheet_num}.png"))
  end
  IO.write(File.join(ROOT, 'build', 'sprites.json'), sprite_data.to_json)
end

task 'html' => %w{extract} do #thumbnails
  # Load source data.
  tpl = Erubis::Eruby.new(IO.read(File.join(ROOT, 'template.erb')))
  slides = JSON.parse(IO.read(File.join(ROOT, 'build', 'extract.json')))
  sprites = JSON.parse(IO.read(File.join(ROOT, 'build', 'sprites.json')))
  # Ignore skipped slides.
  slides.delete_if {|slide| slide['number'] == -1 }
  # Add in extra stuff about images and sprites.
  slides.each do |slide|
    slide['sprite'] = sprites[slide['number']-1]
  end
  # Render the HTML.
  rendered = tpl.result(slides: slides)
  IO.write(File.join(ROOT, 'index.html'), rendered)
end
