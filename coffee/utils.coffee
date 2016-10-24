class @Vec2
    constructor: (@x = 0, @y = 0) ->
    copy: ->
        return new Vec2(@x, @y)
    getAngle: (vec2) ->
        return Math.atan2(@y - vec2.y, @x - vec2.x)
    getDistance: (vec2) ->
        return Math.sqrt(Math.pow(@x - vec2.x, 2) + Math.pow(@y - vec2.y, 2))
    @random: (maxX, maxY) ->
        return new Vec2(~~(Math.random() * maxX), ~~(Math.random() * maxY))
    @fromArray: (arr) ->
        return new Vec2(arr[0], arr[1])

class @Shape
    constructor: ->

class @Circle extends Shape
    constructor: (@x, @y, @radius) ->
        super()
    @fromArray: (arr) ->
        return new Circle(arr[0], arr[1], arr[2])

class @Rectangle extends Shape
    constructor: (@x, @y, @width, @height) ->
        super()
    collides: (rectangle) ->
        return  !(  (rectangle.x >= @x + @width)   ||
        (rectangle.x + rectangle.width <= @x)   ||
        (rectangle.y >= @y + @height)  ||
        (rectangle.y + rectangle.height <= @y) )
    #collidesWhatSides: (rectangle) ->
    #    sides = []
    #    unless rectangle.x >= @x + @width
    #        sides.push ld.COLLISION.RIGHT
    #    unless rectangle.x + rectangle.width <= @x
    #        sides.push ld.COLLISION.LEFT
    #    unless rectangle.y >= @y + @height
    #        sides.push ld.COLLISION.BOTTOM
    #    unless rectangle.y + rectangle.height <= @y
    #        sides.push ld.COLLISION.TOP
    #    return sides

    @fromArray: (arr) ->
        return new Rectangle(arr[0], arr[1], arr[2], arr[3])

class ld.AnimSheet
    constructor: (@url, @size) ->
        @image = new Image()
        @image.src = @url

class ld.Anim
    constructor: (@animid, @sheet, @frameTime, @sequence) ->
        @startTime = Date.now()
        @ticks = 0
        @frameid = 0
    update: ->
        deltaTime = Date.now() - @startTime
        if deltaTime > @frameTime
            @frameid = (@ticks++) % @sequence.length;
            @startTime = Date.now()
    draw: (ctx, pos) ->
        frame = @sequence[@frameid]
        ctx.drawImage(	@sheet.image,
            frame[0] * @sheet.size.x,
            frame[1] * @sheet.size.y,
            @sheet.size.x,
            @sheet.size.y,
            pos.x,
            pos.y,
            @sheet.size.x,
            @sheet.size.y )

