# encoding: utf-8

class Game
  def initialize
    @world = World.new(180)
    @screen = Screen.new(160, 50, @world)
  end
  def run
    loop do
      @world.tick
      render
    end
  end
  def render
    @world.buildings.each do |building|
      @screen.draw(building)
    end
    @screen.draw(@world.player)
    @screen.render
  end
end

class Screen < Struct.new(:width, :height, :world)
  OFFSET = -20
  def initialize width, height, world
    super
    create_frame_buffer
  end
  def create_frame_buffer
    @fb = Framebuffer.new
  end
  def draw renderable
    renderable.each_pixel do |x, y, char|
      @fb.set x, y, char
    end
  end
  def render
    print "\e[H"
    (0...height).each do |y|
      (OFFSET...(width + OFFSET)).each do |x|
        print @fb.get(x, y)
      end
      print "\n"
    end
    puts "| " * (width / 2)
    create_frame_buffer
  end
end

class Framebuffer
  def initialize
    @pixels = Hash.new { |h, k| h[k] = {} }
  end
  def set x, y, char
    @pixels[x][y] = char
  end
  def get x, y
    @pixels[x][y] || " "
  end
end

class World
  def initialize horizon
    @horizon = horizon
    @building_generator = BuildingGenerator.new(self)
    @player = Player.new(25)
    @buildings = [ Building.new(-10, 40, 100) ]
  end
  attr_reader :buildings, :player, :horizon
  def tick
    @building_generator.generate_if_necessary
    buildings.each do |b|
      b.x -= 2
    end
  end
end

class BuildingGenerator < Struct.new(:world)
  def generate_if_necessary
    while (b = world.buildings.last).x < world.horizon
      world.buildings << Building.new(
        b.right_x + minimium_gap + rand(24),
        next_y(b),
        rand(30) + 30
      )
    end
  end
  def minimium_gap; 8 end
  def maximum_height_delta; 10 end
  def minimum_height_clearance; 20; end
  def next_y previous_building
    p = previous_building
    delta = maximum_height_delta * -1 + rand(2 * maximum_height_delta + 1)
    [40, [previous_building.y - delta, minimum_height_clearance].max].min
  end
end

module Renderable
  def each_pixel
    (y...(y + height)).each do |y|
      (x...(x + width)).each do |x|
        rx = x - self.x
        ry = y - self.y
        yield x, y, char(rx, ry)
      end
    end
  end
end

class Building < Struct.new(:x, :y, :width)
  include Renderable
  def initialize x, y, width
    super
    @period = rand(4) + 6
    @window_width = @period - rand(2) - 1
  end
  def height; 50 end
  def char rx, ry
    if ry == 0
      "="
    elsif [ 0, width - 1 ].include? rx
      "|"
    else
      rx % @period >= @period - @window_width && ry % 5 >= 2 ? " " : "#"
    end
  end
  def right_x; x + width end
end

class Player < Struct.new(:y)
  include Renderable
  def x; 0; end
  def width; 1 end
  def height; 3 end
  def char rx, ry
    %w{ @ | L }[ry]
  end
end

Game.new.run