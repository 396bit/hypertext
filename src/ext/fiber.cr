# Make use of crystals open-by-default type system to patch Fiber
# by adding a lazy (nil by default) attribute for holding a
# reference of the current Hypertext context.
class Fiber
  # :nodoc:
  def hypertext
    @hypertext ||= Array(Hypertext).new
  end
end
