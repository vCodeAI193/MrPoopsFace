class_name SoundGen
extends RefCounted
## SoundGen – prozedurale Audioerzeugung (keine externen Audiodateien nötig).
## Liefert kurze AudioStreamWAV-Soundeffekte für Furz, Wurf und Aufprall.

const MIX_RATE: int = 22050


## Wandelt ein Float-Sample-Array (-1..1) in einen 16-Bit-Mono-AudioStreamWAV um.
static func _make_stream(samples: PackedFloat32Array, mix_rate: int = MIX_RATE) -> AudioStreamWAV:
	var data: PackedByteArray = PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		var v: int = int(clampf(samples[i], -1.0, 1.0) * 32767.0)
		data[i * 2] = v & 0xFF
		data[i * 2 + 1] = (v >> 8) & 0xFF
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = mix_rate
	stream.stereo = false
	stream.data = data
	return stream


## Furzgeräusch – Variante (0..n) verändert Tonhöhe, Länge und Flattern.
static func fart(variant: int = 0) -> AudioStreamWAV:
	var duration: float = 0.4 + 0.08 * float(variant % 3)
	var base_freq: float = 70.0 + 22.0 * float(variant % 4)
	var flutter: float = 14.0 + 4.0 * float(variant % 5)
	var n: int = int(MIX_RATE * duration)
	var samples: PackedFloat32Array = PackedFloat32Array()
	samples.resize(n)
	for i in n:
		var t: float = float(i) / MIX_RATE
		var freq: float = base_freq - base_freq * 0.4 * (t / duration)
		var vibrato: float = 1.0 + 0.4 * sin(TAU * flutter * t)
		var saw: float = 2.0 * fmod(freq * vibrato * t, 1.0) - 1.0
		var noise: float = randf_range(-0.3, 0.3)
		var env: float = clampf(t / 0.02, 0.0, 1.0) * (1.0 - t / duration)
		samples[i] = clampf((saw * 0.7 + noise) * env, -1.0, 1.0)
	return _make_stream(samples)


## Wurf-Whoosh – kurzer Rauschimpuls mit An-/Abschwellen.
static func whoosh() -> AudioStreamWAV:
	var duration: float = 0.25
	var n: int = int(MIX_RATE * duration)
	var samples: PackedFloat32Array = PackedFloat32Array()
	samples.resize(n)
	for i in n:
		var t: float = float(i) / MIX_RATE
		var env: float = sin(PI * t / duration)            # sanft hoch und runter
		samples[i] = randf_range(-1.0, 1.0) * env * 0.4
	return _make_stream(samples)


## Aufprall-Platsch – tiefer Ton mit Rauschanteil, der schnell ausklingt.
static func splat() -> AudioStreamWAV:
	var duration: float = 0.18
	var n: int = int(MIX_RATE * duration)
	var samples: PackedFloat32Array = PackedFloat32Array()
	samples.resize(n)
	for i in n:
		var t: float = float(i) / MIX_RATE
		var env: float = (1.0 - t / duration)
		env *= env                                         # schneller Abfall
		var tone: float = sin(TAU * 120.0 * t)
		var noise: float = randf_range(-1.0, 1.0)
		samples[i] = clampf((tone * 0.4 + noise * 0.6) * env, -1.0, 1.0)
	return _make_stream(samples)


## Combo-Jingle – aufsteigender Ton-Arpeggio bei Combo-Steigerung (F135)
static func combo_jingle() -> AudioStreamWAV:
	var notes: PackedFloat32Array = [262.0, 330.0, 392.0, 523.0]  # C-E-G-C (Dur-Dreiklang)
	var samples: PackedFloat32Array = PackedFloat32Array()
	var note_duration: float = 0.08
	for note_freq in notes:
		var n: int = int(MIX_RATE * note_duration)
		for i in n:
			var t: float = float(i) / MIX_RATE
			var env: float = 1.0 - (t / note_duration)
			samples.append(sin(TAU * note_freq * t) * env * 0.3)
	return _make_stream(samples)


## UI-Klick-Sound – kurzer, heller Ton (F136)
static func click() -> AudioStreamWAV:
	var duration: float = 0.1
	var n: int = int(MIX_RATE * duration)
	var samples: PackedFloat32Array = PackedFloat32Array()
	samples.resize(n)
	for i in n:
		var t: float = float(i) / MIX_RATE
		var env: float = 1.0 - (t / duration)
		samples[i] = sin(TAU * 800.0 * t) * env * 0.2
	return _make_stream(samples)


## Countdown-Tick – kurzer, prägnanter Ton (F138)
static func countdown_tick() -> AudioStreamWAV:
	var duration: float = 0.12
	var n: int = int(MIX_RATE * duration)
	var samples: PackedFloat32Array = PackedFloat32Array()
	samples.resize(n)
	for i in n:
		var t: float = float(i) / MIX_RATE
		var env: float = (1.0 - t / duration) * (1.0 - t / duration)
		samples[i] = sin(TAU * 600.0 * t) * env * 0.25
	return _make_stream(samples)
