extends Node3D

@onready var AnimPlayer = $FPSRig/RigAnimation
@onready var FPSRig = $FPSRig
@onready var Audio = $FPSRig/Audio
@onready var BulletPoint = $FPSRig/BulletPoint
@onready var BulletCast = $FPSRig/BulletCast

var CurrentWeapon : WeaponResource
var WeaponStack := [] # array of current available weapons ( inventory )
var WeaponList = {} # all available weapons
var WeaponIndex := 0
var NextWeapon: String

@export var WeaponResources: Array[WeaponResource]	# all available weapons in the game	
@export var StartWeapons: Array[String]		# all weapons in the inventory at game start

signal update_ammo

var recoil := 0.0
var projectiles_shot := 0
var rng = RandomNumberGenerator.new()

func _ready():
	# hide all children of the rig
	for weapon in FPSRig.get_children():
		if weapon is Node3D:
			weapon.visible = false
	
	initialize(StartWeapons) # enter weapon state machine
	

func _input(event):
	
	# change weapons
	
	if event.is_action_pressed("action_weapon_next"):
		WeaponIndex = min(WeaponIndex + 1, WeaponStack.size() - 1)
		unequip(WeaponStack[WeaponIndex])
	
	if event.is_action_pressed("action_weapon_last"):
		WeaponIndex = max(WeaponIndex - 1, 0)
		unequip(WeaponStack[WeaponIndex])
		
	# shoot
	if event.is_action_pressed("action_shoot"):
		shoot()
	
	# reload
	if event.is_action_pressed("action_weapon_reload"):
		reload()

func initialize(_startWeapons: Array) -> void:
	# create a dict to hold references to weapons
	for weapon in WeaponResources:
		WeaponList[weapon.WeaponName] = weapon
	
	# add start weapons
	for weapon in _startWeapons:
		WeaponStack.push_back(weapon)	
		
	CurrentWeapon = WeaponList[WeaponStack[0]]	# set current weapon to first weapon in the stack
	
	# equip after 0.5 seconds
	get_tree().create_timer(0.5, false, true, false).timeout.connect(equip)

# call when first equipping a weapon
func equip() -> void:
	AnimPlayer.queue(CurrentWeapon.ActivateAnimation)
	updateAmmo()
	
# in order to change weapons call unequip first
func unequip(_nextWeapon: String) -> void:
	if _nextWeapon != CurrentWeapon.WeaponName:
		if AnimPlayer.get_current_animation() != CurrentWeapon.DeactivateAnimation:
			AnimPlayer.play(CurrentWeapon.DeactivateAnimation)
		NextWeapon = _nextWeapon

func changeWeapon(weaponName : String) -> void:
	CurrentWeapon = WeaponList[weaponName]
	NextWeapon = ""
	equip()
	
	
func _animation_finished(anim_name):
	if anim_name == CurrentWeapon.DeactivateAnimation:
		changeWeapon(NextWeapon)
		
	# auto fire
	if anim_name == CurrentWeapon.ShootAnimation and CurrentWeapon.ActionType == CurrentWeapon.ActionTypes.AUTO_FIRE:
		if Input.is_action_pressed("action_shoot"):
			shoot()

func shoot() -> void:
	if !AnimPlayer.is_playing(): # enforce fire rate and cant shoot when reloading
		projectiles_shot = 0
		if CurrentWeapon.CurrentAmmo > 0: # check if ammo is in magazine
			CurrentWeapon.CurrentAmmo -= 1
			AnimPlayer.play(CurrentWeapon.ShootAnimation)
			Audio.stream = CurrentWeapon.ShootSound
			Audio.play()
			updateAmmo()
			
			
			# allow multiple projectiles to be shot
			for bullet in CurrentWeapon.ProjectileAmount:
				# launch projectile
				launchProjectile()
				projectiles_shot += 1
				
			# recoil (after shot!)
			recoil = clamp(recoil + CurrentWeapon.RecoilStrength, 0.0, CurrentWeapon.RecoilMaxValue)
			
			
		else:
			reload()
	
func reload() -> void:
	# if magazine is full, dont reload
	if CurrentWeapon.CurrentAmmo == CurrentWeapon.MagazineSize:
		return
	elif !AnimPlayer.is_playing():
		if CurrentWeapon.ReserveAmmo > 0:
			var reload_amount = min(CurrentWeapon.MagazineSize - CurrentWeapon.CurrentAmmo, CurrentWeapon.MagazineSize, CurrentWeapon.ReserveAmmo)
			
			CurrentWeapon.CurrentAmmo += reload_amount
			CurrentWeapon.ReserveAmmo -= reload_amount
			
			updateAmmo()
			
			AnimPlayer.play(CurrentWeapon.ReloadAnimation)
			Audio.stream = CurrentWeapon.ReloadSound
			Audio.play()
		else:
			AnimPlayer.play(CurrentWeapon.OutOfAmmoAnimation)
			Audio.stream = CurrentWeapon.EmptySound
			Audio.play()

func updateAmmo() -> void:
	emit_signal("update_ammo", CurrentWeapon.CurrentAmmo, CurrentWeapon.ReserveAmmo)

func _physics_process(delta):
	
	if CurrentWeapon == null:
		return
		
	# process recoil
	var recoilValue = recoil / CurrentWeapon.RecoilMaxValue
	FPSRig.transform.origin = Vector3(0, CurrentWeapon.RecoilPushUp * recoilValue, CurrentWeapon.RecoilPushBack * recoilValue)
	
	# reset recoil
	recoil = lerp(recoil, 0.0, delta * CurrentWeapon.RecoilReset)
	
func launchProjectile() -> void:
	var projectile = CurrentWeapon.ProjectileType.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	get_tree().root.add_child(projectile)
	var gun_origin = BulletPoint.global_transform.origin
	var gun_end = gun_origin - BulletPoint.global_transform.basis.z
	
	BulletCast.force_raycast_update()
	if BulletCast.is_colliding():
		gun_end = gun_origin + gun_origin.direction_to(BulletCast.get_collision_point())
	
	# calculate spray
	if CurrentWeapon.ProjectileAmount == 1:
		gun_end.y += recoil / CurrentWeapon.RecoilMaxValue
	else:
		# random pattern for multi projectile weapons
		var spray_size = deg_to_rad(5)
		rng.seed = recoil + projectiles_shot
		var new_gun_dir = gun_origin.direction_to(BulletCast.get_collision_point()).rotated(Vector3.UP, rng.randf_range(-spray_size, spray_size))
		rng.seed = recoil + projectiles_shot + 1
		new_gun_dir.y += rng.randf_range(-spray_size, spray_size)
		gun_end = gun_origin + new_gun_dir
	
	projectile.shoot(gun_origin, gun_end)
