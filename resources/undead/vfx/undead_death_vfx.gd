extends Node3D

@onready var fire: GPUParticles3D = $Fire
@onready var sparks: GPUParticles3D = $Sparks
@onready var smoke: GPUParticles3D = $Smoke
@onready var debri: GPUParticles3D = $Debri
@onready var debri_pile: GPUParticles3D = $DebriPile


func activate() -> void:
	# --- ZWIĘKSZANIE LICZBY CZĄSTECZEK (Dostosuj wartości wedle uznania) ---
	fire.amount = 60          # Więcej ognia
	sparks.amount = 300     # Mnóstwo lecących iskier
	smoke.amount = 80         # Gęsty dym po wybuchu
	debri.amount = 40         # Więcej lecących odłamków
	debri_pile.amount = 30    # Więcej gruzu na ziemi
	
	# --- WYBUCHOWOŚĆ: Wymusza wystrzelenie wszystkich cząsteczek na raz (1.0 = 100% natychmiast) ---
	fire.explosiveness = 1.0
	sparks.explosiveness = 1.0
	smoke.explosiveness = 0.95
	debri.explosiveness = 1.0
	debri_pile.explosiveness = 1.0
	
	# --- URUCHOMIENIE EMISJI ---
	fire.emitting = true
	sparks.emitting = true
	smoke.emitting = true
	debri.emitting = true
	debri_pile.emitting = true
