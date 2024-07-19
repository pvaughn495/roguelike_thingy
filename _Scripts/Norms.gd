extends RefCounted
class_name Norms

static func vector2_l1(v : Vector2i) -> float:
	return abs(v.x) + abs(v.y)

static func vector2i_l1(v: Vector2i) -> int:
	return abs(v.x) + abs(v.y)

static func vector2_ln(v: Vector2, n : float = 1.0) -> float:
	return (abs(v.x)**n + abs(v.y)**n)**(1/n)

static func vector2_linf(v: Vector2)->float:
	return max(abs(v.x), abs(v.y))

static func vector2i_linf(v: Vector2i)->int:
	return max(abs(v.x), abs(v.y))
