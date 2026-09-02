extends Node

# =========================================================
# COMBAT MANAGER (Autoload / Singleton)
# =========================================================
#
# ทุกการโจมตีที่ "แน่ใจว่าโดนเป้าหมายแล้ว" ให้เรียก request_hit()
# แทนการเรียก target.take_damage() ตรงๆ
#
# ถ้าในเฟรมเดียวกัน A ขอตี B และ B ก็ขอตี A พอดี (ตีสวนกัน)
# ทั้งคู่จะถูกยกเลิกดาเมจทั้งหมด (Clash) แทนที่จะให้ฝ่ายใดฝ่ายหนึ่ง
# เสียเปรียบเพราะจังหวะการประมวลผลในเฟรม
#
# วิธีติดตั้ง: Project Settings > Autoload > เพิ่มไฟล์นี้ ตั้งชื่อ Node เป็น
# "CombatManager" แล้วเรียกใช้จากที่ไหนก็ได้ในโปรเจกต์ผ่าน CombatManager.request_hit(...)


var pending_hits: Array = []
var resolve_scheduled: bool = false


func request_hit(attacker: Node, target: Node, damage: int) -> void:

	pending_hits.append({
		"attacker": attacker,
		"target": target,
		"damage": damage
	})

	# เลื่อนการตัดสินผลไปท้ายเฟรมปัจจุบัน (call_deferred)
	# เพื่อรอให้ทุก request_hit() ที่จะเกิดขึ้นในเฟรมนี้ถูกเก็บครบก่อน
	# ค่อยตัดสินว่าคู่ไหนตีสวนกันพอดี (Clash) คู่ไหนโดนจริง
	if not resolve_scheduled:
		resolve_scheduled = true
		call_deferred("_resolve_hits")


func _resolve_hits() -> void:

	resolve_scheduled = false

	var cancelled_indices: Array = []

	# หาคู่ที่ตีสวนกันพอดี: A โจมตี B และ B โจมตี A ในเฟรมเดียวกัน
	for i in range(pending_hits.size()):

		for j in range(i + 1, pending_hits.size()):

			var hit_a: Dictionary = pending_hits[i]
			var hit_b: Dictionary = pending_hits[j]

			var is_mutual: bool = (
				hit_a["attacker"] == hit_b["target"]
				and hit_a["target"] == hit_b["attacker"]
			)

			if is_mutual:
				cancelled_indices.append(i)
				cancelled_indices.append(j)


	# ใช้ดาเมจตามปกติ ยกเว้นคู่ที่ถูกยกเลิกเพราะ Clash
	for i in range(pending_hits.size()):

		var hit: Dictionary = pending_hits[i]

		if i in cancelled_indices:

			print("CLASH! ไม่มีใครเสีย HP")
			continue

		var target: Node = hit["target"]

		if is_instance_valid(target) and target.has_method("take_damage"):

			target.take_damage(hit["damage"])


	pending_hits.clear()
