window.ld =
    DEBUG: true
    KEY:
        DOWN: 40
        UP: 38
        LEFT: 37
        RIGHT: 39
        P: 80
        M: 77
        SPACE: 32
        X: 88
        C: 67
        Z: 90
    PARTICLE:
        BASICGUN:
            color: 'cyan'
            size: 2
            range: [[-4, 4], [-4, 4]]
            collidable: true
            friction: 1
            restitution: 1
            lifeTime: 500
            opacityLoss: 0.03
        MOBDEATH:
            color: 'black'
            size: 5
            range: [[-5, 5], [-5, 5]]
            collidable: false
            friction: .95
            restitution: 1
            lifeTime: 1000
            opacityLoss: 0.02
        SPEED:
            color: '#07d'
            size: 4
            range: [[-1, 1], [-4, 1]]
            collidable: false
            friction: 1
            restitution: 1
            lifeTime: 500
            opacityLoss: 0.01
        STRENGTH:
            color: 'orange'
            size: 4
            range: [[-1, 1], [-4, 1]]
            collidable: false
            friction: 1
            restitution: 1
            lifeTime: 500
            opacityLoss: 0.01
        BLOOD:
            color: 'red'
            size: 6
            range: [[-9, 9], [-7,7]]
            collidable: true
            friction: .9
            restitution: 1
            lifeTime: 2000
            opacityLoss: 0.005
    COLLISION:
        TOP: 1
        RIGHT: 2
        BOTTOM: 3
        LEFT: 4
    ORIENTATION:
        RIGHT: 'right',
        LEFT: 'left'
    ENTITY:
        WALL: 10
        PARTICLE: 11
        PLAYER: 21                  # 2... = Character
        FIREBALL: 31                # 3... = Projectile
        LASER: 32
        FLAME: 33
        BOSS_PROJECTILE: 34
        SHADOW1: 41                 # 4... = Monster
        SHADOW2: 42
        SHADOW3: 43
        BOSS: 100
        BASICGUN: 51                # 5... = Weapon
        LASERGUN: 52
        FIREBALL_LAUNCHER: 53
        SMALL_HEALTH_POTION: 61     # 6... = Small Powerup
        SMALL_SPEED_POTION: 62
        SMALL_STRENGTH_POTION: 63
        BIG_HEALTH_POTION: 74       # 7... = Big Powerup
        BIG_SPEED_POTION: 75
        BIG_STRENGTH_POTION: 76
        BASICGUN_LOOT: 81           # 8.. = loot armes
        LASERGUN_LOOT: 82
        FIREBALL_LAUNCHER_LOOT: 83
        TELEPORTER: 91
        UNKNOWN: 999

window.requestAnimFrame = do ->
	window.requestAnimationFrame       ||
	window.webkitRequestAnimationFrame ||
	window.mozRequestAnimationFrame    ||
	(callback) ->
		window.setTimeout(callback, 1000 / 60);
	
