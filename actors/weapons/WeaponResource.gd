extends Resource

class_name WeaponResource

@export var WeaponName: String
@export var ActivateAnimation: String
@export var DeactivateAnimation: String
@export var ShootAnimation: String
@export var ReloadAnimation: String
@export var OutOfAmmoAnimation: String

@export var ShootSound: AudioStream
@export var ReloadSound: AudioStream
@export var EmptySound: AudioStream

@export var CurrentAmmo: int	# The ammo the weapon currently has in its magazine
@export var MagazineSize: int	# How large the magazine is
@export var ReserveAmmo: int	# Ammo that is not in the magazine
@export var MaxAmmo: int		# Max ammo in reserve

enum ActionTypes {
	SINGLE_ACTION,
	BOLT_ACTION,
	BURST_FIRE,
	AUTO_FIRE
}
@export var ActionType: ActionTypes
@export var ProjectileType : PackedScene
@export var ProjectileAmount: int = 1

@export var RecoilStrength : float = 1.0
@export var RecoilMaxValue : float = 10.0
@export var RecoilReset : float = 10.0
@export var RecoilPushBack : float = 0.5
@export var RecoilPushUp : float = 0.1
