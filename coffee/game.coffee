
###################################################################################################
# ENTITY
class ld.Entity
    constructor: (kind, pos, size) ->
        @kind           = kind || ld.ENTITY.UNKNOWN
        @level          = null
        @game 			= null
        @pos 			= pos || new Vec2()
        @size           = size || new Vec2()
        @vel 			= new Vec2()
        @hitbox 		= new Rectangle()
        @spawnAt        = Date.now()
        @random         = ~~(Math.random() * 200)
        @lifeTime       = -1 # -1 = infinity
        @angle			= 0
        @collidable     = false

        # ANIMATIONS
        @currentAnim	= null
        @animations 	= {}
        # PHYSICS
        @friction 		= .9
        @restitution    = 0

        @wallCollisionCallback = null

    update: ->

        if @lifeTime != -1
            if Date.now() - @spawnAt > @lifeTime
                @remove()
        # PHYSICS
        if isNaN @vel.y || isNaN @pos.y || isNaN @vel.x || isNaN @pos.x
            throw new Error "Fatal error Not A Number"
        if @collidable
            @level.forEachOfKind ld.ENTITY.WALL, (wall) =>
                collision = wall.collides(this)
                blockX = false
                blockY = false
                if collision
                    if @wallCollisionCallback?
                        @wallCollisionCallback()
                    if @vel.x > 0 && wall.pos.x > @pos.x
                        blockX = true
                    else if @vel.x < 0 && wall.pos.x + wall.hitbox.width < @pos.x + @hitbox.width
                        blockX = true
                    if @vel.y > 0 && wall.pos.y > @pos.y
                        blockY = true
                    else if @vel.y < 0 && wall.pos.y + wall.hitbox.height < @pos.y + @hitbox.height
                        blockY = true
                if blockY then @vel.y *= -@restitution
                if blockX then @vel.x *= -@restitution

        @pos.x += @vel.x
        @pos.y += @vel.y
        @vel.x *= @friction
        @vel.y *= @friction
        # ANIMATION
        if @currentAnim?
            @currentAnim.update()
    draw: (ctx) ->
        ctx.save()
        ctx.translate(@game.ssx, @game.ssy)
        if @currentAnim
            ctx.save() # Rotation
            ctx.translate(@pos.x + @size.x*.5, @pos.y + @size.y*.5)
            ctx.rotate(@angle)
            ctx.translate(-(@pos.x + @size.x*.5), -(@pos.y + @size.y*.5))
            @currentAnim.draw(ctx, @pos)
            ctx.restore()
        if ld.DEBUG
            if @hitbox
                ctx.strokeStyle = 'red'
                ctx.strokeRect(
                    @pos.x + @hitbox.x,
                    @pos.y + @hitbox.y,
                    @hitbox.width,
                    @hitbox.height  )
        ctx.restore()
    collides: (entity) ->
        if !(entity.hitbox instanceof Rectangle)
            throw new Error("L'entité #{entity} n'a pas de hitbox de type Rectangle")
        if !(@hitbox instanceof Rectangle)
            throw new Error("L'entité #{entity} n'a pas de hitbox de type Rectangle")
        r1 = new Rectangle( @pos.x + @hitbox.x + @vel.x,
                            @pos.y + @hitbox.y + @vel.y,
                            @hitbox.width,
                            @hitbox.height )
        r2 = new Rectangle( entity.pos.x + entity.hitbox.x + entity.vel.x,
                            entity.pos.y + entity.hitbox.y + entity.vel.y,
                            entity.hitbox.width,
                            entity.hitbox.height )

        return r1.collides(r2)
    onWallCollision: (callback) ->
        @wallCollisionCallback = callback
    addAnim: (animid, frameTime, sequence) ->
        if !@animSheet
            throw new Error "AnimSheet non définie"
        @animations[animid] = new ld.Anim(animid, @animSheet, frameTime, sequence)
    setAnim: (animid) ->
        if @currentAnim and @currentAnim.animid == animid
            return # Déjà la même anim
        @currentAnim = @animations[animid]
    setGame: (game) ->
        @game = game
    setLevel: (level) ->
        @level = level
    remove: ->
        @level.unregisterEntity(this)
        delete this


class ld.Powerup extends ld.Entity
    constructor: (kind, pos, size) ->
        super(kind, pos, size)
    update: ->
        @vel.y = Math.sin((Date.now() + @random)  / 100) / 3
        @angle = @vel.y / 5
        super()

class ld.WeaponLoot extends ld.Powerup
    constructor: (kind, pos) ->
        size =
            if      kind == ld.ENTITY.BASICGUN_LOOT             then new Vec2(30, 30)
            else if kind == ld.ENTITY.LASERGUN_LOOT             then new Vec2(54, 27)
            else if kind == ld.ENTITY.FIREBALL_LAUNCHER_LOOT     then new Vec2(36, 35)
        super(kind, pos, size)
        @hitbox = new Rectangle(7, 7, 20, 20)
        spriteName =
            if kind == ld.ENTITY.BASICGUN_LOOT                  then 'basicgun'
            else if kind == ld.ENTITY.LASERGUN_LOOT             then 'lasergun'
            else if kind == ld.ENTITY.FIREBALL_LAUNCHER_LOOT    then 'fireball-launcher'
        @animSheet  = new ld.AnimSheet('assets/' + spriteName + '.png', @size)
        @addAnim('default', 1000, [[0, 0]])
        @setAnim('default')
    update: ->
        if @level.player.collides(this)
            if @level.player.weapon1?
                @level.player.weapon1.remove()
            @level.player.weapon1 =
                if @kind == ld.ENTITY.BASICGUN_LOOT
                    new ld.Basicgun(@pos.copy())
                else if @kind == ld.ENTITY.LASERGUN_LOOT
                    new ld.Lasergun(@pos.copy())
                else if @kind == ld.ENTITY.FIREBALL_LAUNCHER_LOOT
                    new ld.FireballLauncher(@pos.copy())
            @level.registerEntity(@level.player.weapon1)
            @remove()
        super()


class ld.SmallPotion extends ld.Powerup
    constructor: (kind, pos) ->
        super(kind, pos, new Vec2(27, 30))
        @hitbox = new Rectangle(7, 7, 20, 20)
        @animSheet  = new ld.AnimSheet('assets/small-potion.png', @size)
        @addAnim('health', 1000, [[0, 0]])
        @addAnim('speed', 1000, [[0, 1]])
        @addAnim('strength', 1000, [[0, 2]])
        @setAnim(
            if      @kind == ld.ENTITY.SMALL_HEALTH_POTION then 'health'
            else if @kind == ld.ENTITY.SMALL_SPEED_POTION then 'speed'
            else if @kind == ld.ENTITY.SMALL_STRENGTH_POTION then 'strength'
        )
    update: ->
        if @level.player.collides(this)
            if      @kind == ld.ENTITY.SMALL_HEALTH_POTION
                @level.player.health += 2
                @level.player.health = Math.min(10, @level.player.health)
            else if @kind == ld.ENTITY.SMALL_SPEED_POTION
                @level.player.speedBoost(5000)
            else if @kind == ld.ENTITY.SMALL_STRENGTH_POTION
                @level.player.strengthBoost(10000)
            @remove()
        super()

class ld.BigPotion extends ld.Powerup
    constructor: (kind, pos) ->
        super(kind, pos, new Vec2(33, 33))
        @hitbox = new Rectangle(7, 7, 20, 20)
        @animSheet  = new ld.AnimSheet('assets/big-potion.png', @size)
        @addAnim('health', 1000, [[0, 0]])
        @addAnim('speed', 1000, [[0, 1]])
        @addAnim('strength', 1000, [[0, 2]])
        @setAnim(
            if      @kind == ld.ENTITY.BIG_HEALTH_POTION then 'health'
            else if @kind == ld.ENTITY.BIG_SPEED_POTION then 'speed'
            else if @kind == ld.ENTITY.BIG_STRENGTH_POTION then 'strength'
        )
    update: ->
        if @level.player.collides(this)
            if      @kind == ld.ENTITY.BIG_HEALTH_POTION
                @level.player.health += 5
                @level.player.health = Math.min(10, @level.player.health)
            else if @kind == ld.ENTITY.BIG_SPEED_POTION
                @level.player.speedBoost(20000)
            else if @kind == ld.ENTITY.BIG_STRENGTH_POTION
                @level.player.strengthBoost(30000)
            @remove()
        super()

# TELEPORTER
class ld.Teleporter extends ld.Entity
    constructor: (pos, size, levelid, coords) ->
        super(ld.ENTITY.TELEPORTER, pos, size)
        @hitbox         = new Rectangle(0, 0, @size.x, @size.y)
        @levelid        = levelid
        @coords         = coords
    update: ->
        if @level.player.collides(this) && (@level.isCleared() || ld.DEBUG)
            if @coords?
                @level.player.pos = @coords.copy()
            @game.loadLevel(@levelid)
            this.remove()
    draw: (ctx) ->
        ctx.globalAlpha = (Math.sin(Date.now() / 200)  + 1) / 2
        ctx.fillStyle = 'white'
        if @level.player.collides(this) && !@level.isCleared()
            ctx.fillStyle = 'red'
        ctx.fillRect(@pos.x, @pos.y, @size.x, @size.y)
        ctx.globalAlpha = 1


# PARTICLE
randomFloatBetween = (min, max) ->
    return Math.random() * (max - min) + min

class ld.Particle extends ld.Entity
    constructor: (pos, options) ->
        if options? && options.size?
            @size = new Vec2(options.size, options.size)
        else @size = new Vec2(2, 2)
        super(ld.ENTITY.PARTICLE, pos, @size)
        @hitbox         = new Rectangle(0, 0, 2, 2)
        @collidable     = options.collidable    || true
        @color          = options.color         || 'red'
        @range          = options.range         || [[-2, 2], [-2, 2]]
        @friction       = options.friction      || 1
        @restitution    = options.restitution   || 1
        @lifeTime       = options.lifeTime      || -1
        @opacityLoss    = options.opacityLoss   || 0
        @opacity        = 1

        @vel = new Vec2(
            randomFloatBetween(@range[0][0], @range[0][1]),
            randomFloatBetween(@range[1][0], @range[1][1])
        )
    update: ->
        @opacity -= @opacityLoss
        super()
    draw: (ctx) ->
        ctx.globalAlpha = if @opacity < 0 then 0 else @opacity
        ctx.fillStyle = @color
        ctx.fillRect(@pos.x, @pos.y, @size.x, @size.y)
        ctx.globalAlpha = 1
    @sendParticles: (level, amount, pos, options) ->
        for i in [0...amount]
            particle = new ld.Particle(pos.copy(), options)
            level.registerEntity(particle)

# WALL
class ld.Wall extends ld.Entity
    constructor: (pos, size) ->
        super(ld.ENTITY.WALL, pos, size)
        @hitbox = new Rectangle(0, 0, @size.x, @size.y)
    draw: (ctx) ->
        #if ld.DEBUG
        ctx.fillStyle = 'black'

        ctx.lineWidth = 10
        ctx.strokeStyle = 'rgba(0, 0, 0, 0.1)'
        ctx.strokeRect(@pos.x, @pos.y, @size.x, @size.y)
        ctx.fillRect(@pos.x, @pos.y, @size.x, @size.y)
        ctx.lineWidth = 1
        super(ctx)

# WEAPON
class ld.Weapon extends ld.Entity
    constructor: (kind, pos, size, spriteName, spriteOffset, cooldown) ->
        super(kind, pos, size)
        @spriteOffset   = spriteOffset
        @cooldown       = cooldown
        @lastShot       = new Date(0)
        @animSheet      = new ld.AnimSheet('assets/' + spriteName + '.png', @size)
        @addAnim('right', 1000, [[0, 0]])
        @addAnim('left', 1000, [[0, 1]])
        @setAnim('right')
    canShoot: ->
        return Date.now() - @lastShot > @cooldown
    shoot: ->
        @lastShot = Date.now()
    update: ->
        @setAnim(@level.player.orientation)
        if @level.player.orientation == ld.ORIENTATION.LEFT
            @angle = @game.mousePos.getAngle(@pos) + 0.0174532925*180
        else
            @angle = @game.mousePos.getAngle(@pos)
        super()
    draw: (ctx) ->
        ctx.save()
        if @level.player.orientation == ld.ORIENTATION.RIGHT
            ctx.translate(@spriteOffset.x, @spriteOffset.y)
        else
            ctx.translate(-@spriteOffset.x + @level.player.size.x - @size.x, @spriteOffset.y)
        super(ctx)
        ctx.restore()

# BASICGUN
class ld.Basicgun extends ld.Weapon
    constructor: (pos) ->
        super(ld.ENTITY.BASICGUN, pos, new Vec2(30, 30),
                'basicgun', new Vec2(-5, -5), 500) # last arg: cooldown
    shoot: (angle) ->
        if @canShoot()
            @level.registerEntity(new ld.Flame(@pos.copy(), angle, 7)) # 10 = power
            super()

# LASERGUN
class ld.Lasergun extends ld.Weapon
    constructor: (pos) ->
        super(ld.ENTITY.LASERGUN, pos, new Vec2(54, 27),
                'lasergun', new Vec2(20, 10), 200)
    shoot: (angle) ->
        if @canShoot()
            @level.registerEntity(new ld.Laser(@pos.copy(), angle, 25)) # 10 = power
            super()

# LASERGUN
class ld.FireballLauncher extends ld.Weapon
    constructor: (pos) ->
        super(ld.ENTITY.FIREBALL_LAUNCHER, pos, new Vec2(36, 35),
            'fireball-launcher', new Vec2(10, 5), 200)
    shoot: (angle) ->
        if @canShoot()
            @level.registerEntity(new ld.Fireball(@pos.copy(), angle, 15)) # 10 = power
            super()


# PROJECTILE : abstract
class ld.Projectile extends ld.Entity
    constructor: (kind, pos, size, spriteName, angle, power, damage) ->
        super(kind, pos, size)
        @collidable     = true
        @angle          = angle
        @damage         = damage
        @friction       = 0.99
        @restitution    = 0.9
        @vel            = new Vec2(Math.cos(angle) * power, Math.sin(angle) * power)
        @animSheet 		= new ld.AnimSheet('assets/' + spriteName + '.png', @size)
        @addAnim('default', 1000, [[0, 0]])
        @setAnim('default')
    update: ->
        @angle = Math.atan2(@pos.y - @pos.y + @vel.y, @pos.x - @pos.x + @vel.x)
        super()

# FIREBALL
class ld.Fireball extends ld.Projectile
    constructor: (pos, angle, power) ->
        super(ld.ENTITY.FIREBALL, pos, new Vec2(36, 21), 'fireball', angle, power, 3) # last argument = damage
        @hitbox         = new Rectangle(10, 10, 10, 10)
        @lifeTime       = 1000


class ld.BossProjectile extends ld.Projectile
    constructor: (pos, angle, power) ->
        super(ld.ENTITY.BOSS_PROJECTILE, pos, new Vec2(13, 13), 'boss-projectile', angle, power, 1)
        @hitbox         = new Rectangle(0, 0, 13, 13)
        @lifeTime       = 5000
        @friction       = 1
        @collidable     = true
    update: ->
        if this.collides(@level.player)
            @level.player.damage(1)
        super()


# FIREBALL
class ld.Flame extends ld.Projectile
    constructor: (pos, angle, power) ->
        super(ld.ENTITY.FIREBALL, pos, new Vec2(27, 12), 'flame', angle, power, 1) # last argument = damage
        @hitbox         = new Rectangle(10, 10, 10, 10)
        @lifeTime       = 2000
        @onWallCollision =>
            ld.Particle.sendParticles(@level, 10, @pos.copy(), ld.PARTICLE.BASICGUN)

# LASER
class ld.Laser extends ld.Projectile
    constructor: (pos, angle, power) ->
        super(ld.ENTITY.FIREBALL, pos, new Vec2(30, 15), 'laser', angle, power, 1) # last argument = damage
        @hitbox         = new Rectangle(0, 0, 30, 15)
        @lifeTime       = 1000



# CHARACTER : abstract
class ld.Character extends ld.Entity
    @HEART = new ld.AnimSheet('assets/heart.png')
    @HALF_HEART = new ld.AnimSheet('assets/half-heart.png')
    constructor: (kind, pos, size, health, speed) ->
        super(kind, pos, size)
        @orientation = ld.ORIENTATION.RIGHT
        @health      = health
        @speed       = speed || 1
        @collidable  = true
    damage: (amount) ->
        @health -= amount
        @health = Math.max(@health, 0)
        if @health <= 0
            @die()
    die: ->
        @remove()
    drawHeart: (ctx, x, y, half) ->
        if half
            ctx.drawImage(ld.Character.HALF_HEART.image, x, y)
        else ctx.drawImage(ld.Character.HEART.image, x, y)
    update: ->
        if Math.abs(@vel.x) > 0.1 || Math.abs(@vel.y) > 0.1
            @setAnim('run_' + @orientation)
        else
            @setAnim('idle_' + @orientation)
        super()
    draw: (ctx) ->
        health = @health || 0
        x = @pos.x + @size.x/2 - health * 5
        y = @pos.y - 15
        while health != 0
            if health >= 2
                @drawHeart(ctx, x, y, false)
                x += 18
                health -= 2
            else
                @drawHeart(ctx, x, y, true)
                x += 10
                health--

        super(ctx)

# MONSTER : abstract
handleCollision = (e1, e2) ->
    angle = e1.pos.getAngle(e2.pos)
    if !(e1 instanceof ld.Boss)
        e1.vel.x = Math.cos(angle) * e1.speed
        e1.vel.y = Math.sin(angle) * e1.speed
    if !(e2 instanceof ld.Boss)
        e2.x = Math.sin(angle) * e2.speed
        e2.y = Math.cos(angle) * e2.speed

class ld.Monster extends ld.Character
    constructor: (kind, pos, size, health, strength, speed) ->
        super(kind, pos, size, health, speed)
        @tracking           = true
        @strength           = strength
        @shadowEffectSpeed  = ~~(Math.random() * 5) + 5
        @shadowEffectStart  = ~~(Math.random() * 3000) + 100
        @speed += Math.random()
    draw: (ctx) ->
        #alpha = (Math.sin((Date.now() + @shadowEffectStart)  / @shadowEffectStart)  + 1) / 2
        #alpha = Math.max(Math.min(alpha, 1), .6)
        #ctx.save()
        #ctx.globalAlpha = alpha
        super(ctx)
        #ctx.restore()
    die: ->
        ld.Particle.sendParticles(@level, 7, @pos.copy(), ld.PARTICLE.MOBDEATH)
        super()
    update: ->
        if @pos.x+@hitbox.width < 0 || @pos.y+@hitbox.height < 0  || @pos.x + @hitbox.width > @game.width || @pos.y + @hitbox.height > @game.height
            return @remove()



        if @vel.x == 0
            @vel.y *= 4
        if @vel.y == 0
            @vel.x *= 4

        if @level.player.collides(this)
            @level.player.damage(@strength)

        @level.forEachMonster (monster) =>
            @tracking = true
            if monster != this && monster.collides(this)
                @tracking = false
                handleCollision(this, monster)


        @level.forEachProjectile (projectile) =>
            if projectile.kind != ld.ENTITY.BOSS_PROJECTILE && projectile.collides(this)
                @damage(projectile.damage)
                projectile.remove()

        @orientation = if @level.player.pos.x > @pos.x
            ld.ORIENTATION.RIGHT
        else
            @orientation = ld.ORIENTATION.LEFT

        super()

# SHADOW1
class ld.Shadow1 extends ld.Monster
    constructor: (pos) ->
        super(ld.ENTITY.SHADOW1, pos, new Vec2(30, 30), 4, 1, 1)
        @hitbox         = new Rectangle(10, 10, @size.x-10, @size.y-10)
        @animSheet      = new ld.AnimSheet('assets/shadow1.png', @size)
        @addAnim('idle_right', 100, [[0, 0]])
        @addAnim('idle_left', 100, [[0, 1]])
        @addAnim('run_right', 100, [[0, 0], [1, 0], [2, 0]])
        @addAnim('run_left', 100, [[0, 1], [1, 1], [2, 1]])
        @setAnim('run_right')
    update: ->
        if @tracking && @level.player.pos.getDistance(@pos) > 20
            angle = @level.player.pos.getAngle(@pos)
            @vel.x = Math.cos(angle) * @speed
            @vel.y = Math.sin(angle) * @speed
        super()

class ld.Shadow2 extends ld.Monster
    constructor: (pos) ->
        super(ld.ENTITY.SHADOW1, pos, new Vec2(48, 42), 7, 2, 2)
        @hitbox         = new Rectangle(10, 10, @size.x-10, @size.y-10)
        @animSheet      = new ld.AnimSheet('assets/shadow2.png', @size)
        @addAnim('idle_right', 100, [[0, 0]])
        @addAnim('idle_left', 100, [[0, 1]])
        @addAnim('run_right', 100, [[0, 0], [1, 0], [2, 0]])
        @addAnim('run_left', 100, [[0, 1], [1, 1], [2, 1]])
        @setAnim('run_right')
    update: ->
        if @tracking && @level.player.pos.getDistance(@pos) > 20
            angle = @level.player.pos.getAngle(@pos)
            if @vel.x != 0 && @vel.y != 0
                angle += 20
            @vel.x = Math.cos(angle) * @speed
            @vel.y = Math.sin(angle) * @speed
        super()

class ld.Shadow3 extends ld.Monster
    constructor: (pos) ->
        super(ld.ENTITY.SHADOW3, pos, new Vec2(42, 60), 12, 4, 3)
        @hitbox         = new Rectangle(15, 15, @size.x-20, @size.y-40)
        @animSheet      = new ld.AnimSheet('assets/shadow3.png', @size)
        @addAnim('idle_right', 100, [[0, 0]])
        @addAnim('idle_left', 100, [[0, 1]])
        @addAnim('run_right', 100, [[0, 0], [1, 0], [2, 0]])
        @addAnim('run_left', 100, [[0, 1], [1, 1], [2, 1]])
        @setAnim('run_right')
    update: ->
        if @tracking
            angle = @level.player.pos.getAngle(@pos)
            speed = @speed

            if @level.player.pos.getDistance(@pos) > 150
                speed *= 1.6

            if @level.player.pos.getDistance(@pos) > 20
                @vel.x = Math.cos(angle) * speed
                @vel.y = Math.sin(angle) * speed
        super()

class ld.Boss extends ld.Monster
    constructor: (pos) ->
        super(ld.ENTITY.BOSS, pos, new Vec2(204, 150), 20, 5, 0)
        @hitbox         = new Rectangle(15, 15, @size.x-20, @size.y-20)
        @animSheet      = new ld.AnimSheet('assets/boss.png', @size)
        @addAnim('idle_right', 100, [[0, 0]])
        @addAnim('idle_left', 100, [[0, 1]])
        @setAnim('idle_left')
        @spawnedShadow3 = false
    damage: ->
        if @level.isCleared()
            for i in [0...50]
                do (i) =>
                    setTimeout =>
                        if i < 49
                            @game.ssx = ~~(Math.random()*10) - 5
                            @game.ssy = ~~(Math.random()*10) - 5
                        else
                            @game.ssx = 0
                            @game.ssy = 0
                    , i * 10
            super(1)
    die: ->
        @level.player.setInvicibleFor(5000000)
        for i in [0...500]
            do (i) =>
                setTimeout =>
                    if i < 499
                        @game.ssx = ~~(Math.random()*50) - 25
                        @game.ssy = ~~(Math.random()*50) - 25
                    else
                        @game.ssx = 0
                        @game.ssy = 0
                        @game.stop()
                        ld.setState('congratz')
                , i * 10
    update: ->
        if Date.now() % 150 == 0
            from = new Vec2(@pos.x + @size.x / 2, @pos.y + @size.x / 2)
            angle = @level.player.pos.getAngle(from)
            projectile = new ld.BossProjectile(from, angle, 5)
            @level.registerEntity(projectile)
        if Date.now() % 300 == 0
            monster = new ld.Shadow1(new Vec2(40, 21))
            @level.registerEntity(monster)
        if Date.now() % 510 == 0
            monster = new ld.Shadow2(new Vec2(360, 60))
            @level.registerEntity(monster)
        if !@spawnedShadow3 || Date.now() % 1200 == 0
            @spawnedShadow3 = true
            monster = new ld.Shadow3(new Vec2(360, 420))
            @level.registerEntity(monster)
        super()

# PLAYER
class ld.Player extends ld.Character
    constructor: (pos) ->
        super(ld.ENTITY.PLAYER, pos, new Vec2(24, 39), 6)
        @speed                  = 4
        @hitbox                 = new Rectangle(0, 10, @size.x, @size.y - 20)
        @animSheet 		        = new ld.AnimSheet('assets/player.png', @size)
        @weapon1                = null
        @invincibleUntil        = new Date(0)
        @speedBoostUntil        = new Date(0)
        @strengthBoostUntil     = new Date(0)
        @dead                   = false
        @setInvicibleFor(2000)
        @addAnim('idle_right', 100, [[0, 0]])
        @addAnim('idle_left', 100, [[0, 1]])
        @addAnim('run_right', 100, [[1, 0], [2, 0], [3, 0], [4, 0]])
        @addAnim('run_left', 100, [[1, 1], [2, 1], [3, 1], [4, 1]])
        @setAnim('idle_right')
    strengthBoost: (ms) ->
        @strengthBoostUntil= Date.now() + ms
    speedBoost: (ms) ->
        @speedBoostUntil= Date.now() + ms
    setInvicibleFor: (ms) ->
        @invincibleUntil= Date.now() + ms
    isInvincible: ->
        return @invincibleUntil > Date.now()
    hasStrengthBoost: ->
        return @strengthBoostUntil > Date.now()
    hasSpeedBoost: ->
        return @speedBoostUntil > Date.now()
    damage: (amount) ->
        unless @isInvincible()
            if @hasStrengthBoost
                amount = Math.max(0, Math.round(amount * .7))
            super(amount)
            ld.Particle.sendParticles(@level, 30, @pos.copy(), ld.PARTICLE.BLOOD)
            @setInvicibleFor(2000)
    die: ->
        unless @dead
            @dead = true
            ld.setState('respawn')
    update: ->
        # !! atan2(y, x) not (x, y)
        angle = @game.mousePos.getAngle(@pos)
        # WEAPON 1 SHOOT
        if @hasSpeedBoost()
            @speed = 6
            if Date.now() % 5 == 0
                ld.Particle.sendParticles(@level, 1, new Vec2(@pos.x, @pos.y + @size.y/2), ld.PARTICLE.SPEED)
        else
            @speed = 4
        if @hasStrengthBoost()
            if Date.now() % 5 == 0
                ld.Particle.sendParticles(@level, 1, new Vec2(@pos.x, @pos.y + @size.y/2), ld.PARTICLE.STRENGTH)

        if @weapon1?
            if @game.keys[ld.KEY.X]
                @weapon1.shoot(angle)
            @weapon1.pos = @pos
        if @game.mouseDown && @game.mousePos.getDistance(@pos) > @speed * 5
            @vel.x = Math.cos(angle) * @speed
            @vel.y = Math.sin(angle) * @speed
        if @game.mousePos.x > @pos.x
            @orientation = ld.ORIENTATION.RIGHT
        else
            @orientation = ld.ORIENTATION.LEFT
        super()
    draw: (ctx) ->
        if @isInvincible() && ~~(Date.now() / 150) % 2 == 0
            ctx.globalAlpha = .5
            super(ctx)
            ctx.globalAlpha = 1
        else
            super(ctx)

class ld.Factory
    @weapon: (kind, pos) ->
    @monster: (kind, pos) ->
        if kind == ld.ENTITY.SHADOW1 then MonsterClass = ld.Shadow1
        if kind == ld.ENTITY.SHADOW2 then MonsterClass = ld.Shadow2
        if kind == ld.ENTITY.SHADOW3 then MonsterClass = ld.Shadow3
        if kind == ld.ENTITY.BOSS    then MonsterClass = ld.Boss
        return new MonsterClass(pos)
    @powerup: (kind, pos) ->
        if kind >= 60 && kind <= 69
            powerup = new ld.SmallPotion(kind, pos)
        else if kind >= 70 && kind <= 79
            powerup = new ld.BigPotion(kind, pos)
        else if kind >= 80 && kind <= 89
            powerup = new ld.WeaponLoot(kind, pos)
        else throw new Error 'not a powerup'

# LEVEL
class ld.Level
    constructor: (game, id, existingPlayer) ->
        @game 			= game
        @id 			= id
        @walls 			= []
        @entities		= {}
        @entityCount 	= 0
        @player         = existingPlayer || null
        data = ld.DATA.levels[id]
        console.log data
        @addWalls(data)
        @addPowerups(data)
        @addMonsters(data)
        @addTeleporters(data)
        if !existingPlayer?
            @addPlayer(data)
        else # On passe les entités à garder dans les entités de ce niveau
            @player.pos = Vec2.fromArray(data.playerPos)
            @registerEntity(@player)
            if @player.weapon1?
                @registerEntity(@player.weapon1)

        $('#container').css('background', data.color)
    isCleared: ->
        cleared = true
        @forEachMonster (monster) ->
            cleared = false
            return
        return cleared
    addPlayer: (data) ->
        pos    = Vec2.fromArray(data.playerPos)
        @player = new ld.Player(pos)
        @registerEntity(@player)

    addTeleporters: (data) ->
        for teleporterData in data.teleporters
            levelid = teleporterData[0]
            pos         = Vec2.fromArray(teleporterData[1...3])
            size        = Vec2.fromArray(teleporterData[3...5])
            #coords      = Vec2.fromArray(teleporterData[5...7])
            teleporter = new ld.Teleporter(pos, size, levelid) # ,coords
            @registerEntity(teleporter)
    addPowerups: (data) ->
        for powerupData in data.powerups
            kind = powerupData[0]
            pos = Vec2.fromArray(powerupData[1...3])
            powerup = ld.Factory.powerup(kind, pos)
            @registerEntity(powerup)
    addWalls: (data) ->
        # Level bounds
        @registerEntity(new ld.Wall(new Vec2(0, -10), new Vec2(@game.width, 10)))
        @registerEntity(new ld.Wall(new Vec2(-10, 0), new Vec2(10, @game.height)))
        @registerEntity(new ld.Wall(new Vec2(@game.width, 0), new Vec2(10, @game.height)))
        @registerEntity(new ld.Wall(new Vec2(0, @game.height), new Vec2(@game.width, 10)))
        # Wall data
        for wallData in data.walls
            pos    = Vec2.fromArray(wallData[0...2])
            size   = Vec2.fromArray(wallData[2...4])
            wall   = new ld.Wall(pos, size)
            @registerEntity(wall)
    addMonsters: (data) ->
        for monsterData in data.monsters
            kind = monsterData[0]
            pos = Vec2.fromArray(monsterData[1...3])
            monster = ld.Factory.monster(kind, pos)
            @registerEntity(monster)
    forEachProjectile: (callback) ->
        for id, entity of @entities
            if entity.kind >= 30 && entity.kind <= 39 # 3... = projectile
                callback(entity)
    forEachMonster: (callback) ->
        for id, entity of @entities
            if entity.kind >= 40 && entity.kind <= 49 # 4... = monster
                callback(entity)
    forEachOfKind: (kind, callback) ->
        for id, entity of @entities
            if entity.kind == kind
                callback(entity)
    registerEntity: (entity) ->
        @entities[++@entityCount] = entity
        entity.setGame(@game)
        entity.setLevel(this)
        entity.id = @entityCount
    unregisterEntity: (entity) ->
        delete @entities[entity.id]
    drawGuide: (ctx) ->
        ctx.beginPath()
        ctx.moveTo(@player.pos.x, @player.pos.y)
        ctx.lineTo(@game.mousePos.x, @game.mousePos.y)
        ctx.closePath()

        ctx.strokeStyle = 'rgba(255, 255, 255, .05)'
        ctx.stroke()
    tick: ->
        @game.ctx.clearRect(0, 0, @game.width, @game.height)
        @drawGuide(@game.ctx)
        for id, entity of @entities
            entity.update()
            entity.draw(@game.ctx)

# GAME
class ld.Game
    constructor: (width, height, ctx) ->
        @width          = width
        @height         = height
        @ssx            = 0 # screenshake
        @ssy            = 0
        @ctx 			= ctx
        @started 		= false
        @level 			= null
        @keys           = {}
        @mousePos       = new Vec2()
        @mouseDown      = false
        @loadLevel(1)
    respawnPlayer: ->
        if !@level.player? || !@level.player.dead
            return console.warn 'wtf'
        @level.player.health = 6
        @level.player.dead = false
        if @level.player.weapon1?
            @level.player.weapon1.remove()
            @level.player.weapon1 = null
        weapon = null
        ld.setState('game')
        if @level.id < 3
            @loadLevel(1)
            weapon = null
        else if @level.id == 4 || @level.id == 5 || @level.id == 6
            @loadLevel(4)
            weapon = new ld.Basicgun()
        else if @level.id == 7 || @level.id > 7
            @loadLevel(7)
            weapon = new ld.Lasergun()
        else throw 'should not happen'
        if weapon?
            @level.player.weapon1 = weapon
            @level.registerEntity(weapon)
    loadLevel: (levelid) ->
        player =
            if @level? && @level.player instanceof ld.Player then @level.player else null
        @level = new ld.Level(this, levelid, player)
    tick: ->
        if @started
            if @level
                @level.tick()
            window.requestAnimFrame => @tick()
    start: ->
        ld.setState('game')
        @started = true
        @tick()
    stop: ->
        @started = false

ld.setState = (state) ->
    $state = $('.state#' + state)
    if $state.length != 1
        throw new Error 'state error'
    $('.state').hide()
    $state.show()
    $('#overlay').show().fadeOut(2000)

ld.playingIntro = false
ld.introCancelled = false
ld.playIntro = ->
    ld.playingIntro = true
    insertText = (text, x, y, lifeTime) ->
        $t = $('<div></div>')
            .addClass('text').html(text).css(left: x, top: y).appendTo('#texts').hide().fadeIn()
        setTimeout =>
            $t.fadeOut()
        , (lifeTime || 1000)
    if !ld.introCancelled
        ld.setState('intro1')
    insertText('Shadow creatures', 420, 70, 20000)
    setTimeout (=> insertText('<b>hate light</b>', 420, 100, 20000)), 1000
    setTimeout (=> insertText('so they <b>absorb it</b>', 420, 130, 20000)), 3000
    setTimeout (=> insertText('this planet is about to lose its sun', 50, 430, 20000)), 6000

    setTimeout ( =>
        $('.text').remove()
        if !ld.introCancelled
            ld.setState('intro2')
        setTimeout (=> insertText('They use <b>monster fuel</b>', 50, 50, 20000)), 1000
        setTimeout (=> insertText('They get it from the <b>depths</b> of this planet', 50, 80, 20000)), 3000
        setTimeout (=> insertText('If they get enough of it', 50, 130, 20000)), 5000
        setTimeout (=> insertText('the sun will die', 360, 130, 20000)), 7000
        setTimeout (=> insertText('and the planet too', 360, 160, 20000)), 9000
        setTimeout (=> insertText('which would be a little sad', 360, 190, 20000)), 10000
        setTimeout (=> insertText('<b>you go first :)</b>', 150, 320, 20000)), 12000
        setTimeout (=> insertText('Press X', 150, 350, 20000)), 12000
    ), 12000

$ ->
    canvas = document.getElementById 'game'
    game = new ld.Game(
        800,
        500,
        canvas.getContext '2d'
    )
    ld.playIntro()
    $('#respawn').click =>
        game.respawnPlayer()
    # EVENTS
    document.addEventListener 'keydown', (e) ->
        if e.keyCode == ld.KEY.X && ld.playingIntro
            ld.playingIntro = false
            ld.introCancelled = true
            $('#texts').hide()
            ld.setState('game')
            game.start()
        if ~[40, 38, 32].indexOf e.keyCode
            e.preventDefault()
        game.keys[e.keyCode] = true
    document.addEventListener 'keyup', (e) ->
        delete game.keys[e.keyCode]
    document.addEventListener 'mousemove', (e) ->
        game.mousePos = new Vec2(
            e.pageX - canvas.offsetLeft,
            e.pageY - canvas.offsetTop
        )
    document.addEventListener 'mousedown', (e) ->
        game.mouseDown = true
    document.addEventListener 'mouseup', (e) ->
        game.mouseDown = false



    if ld.DEBUG
        document.addEventListener 'contextmenu', (e) ->
            e.preventDefault()
            gm.level.player.pos = gm.mousePos.copy()

    window.gm = game