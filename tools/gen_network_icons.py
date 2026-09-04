from PIL import Image, ImageDraw
import os

OUT = r"d:\Projects\SmartBuild\SmartBuild-Godot\assets\icons\network"
os.makedirs(OUT, exist_ok=True)

SIZE = 256
CX, CY = SIZE // 2, SIZE // 2


def new_img():
	return Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))


def save(img, name):
	path = os.path.join(OUT, name)
	img.save(path, "PNG")
	print("wrote", path)


def round_rect(draw, xy, r, fill, outline=None, width=2):
	draw.rounded_rectangle(xy, radius=r, fill=fill, outline=outline, width=width)


def shadow(draw, xy, r=12):
	x0, y0, x1, y1 = xy
	draw.rounded_rectangle((x0 + 4, y0 + 6, x1 + 4, y1 + 6), radius=r, fill=(0, 0, 0, 70))


# --- Modem ---
im = new_img()
d = ImageDraw.Draw(im)
body = (48, 110, 208, 190)
shadow(d, body, 14)
round_rect(d, body, 14, (230, 190, 70, 255), (255, 230, 140, 255), 3)
for i in range(6):
	x = 70 + i * 22
	d.rectangle((x, 128, x + 10, 172), fill=(40, 45, 55, 220))
for i, col in enumerate([(80, 220, 100), (80, 180, 255), (255, 90, 90)]):
	d.ellipse((70 + i * 28, 98, 86 + i * 28, 114), fill=col + (255,))
d.ellipse((188, 140, 212, 164), fill=(60, 70, 85, 255), outline=(200, 210, 220, 255), width=2)
d.rectangle((40, 145, 55, 158), fill=(50, 55, 65, 255))
save(im, "icon_modem.png")

# --- Router ---
im = new_img()
d = ImageDraw.Draw(im)
body = (55, 120, 201, 188)
shadow(d, body, 12)
round_rect(d, body, 12, (70, 150, 210, 255), (160, 210, 255, 255), 3)
for ax in (78, 178):
	d.rectangle((ax - 5, 48, ax + 5, 125), fill=(90, 100, 115, 255))
	d.ellipse((ax - 10, 36, ax + 10, 56), fill=(120, 130, 145, 255))
for i in range(4):
	x = 78 + i * 28
	d.rounded_rectangle((x, 145, x + 18, 168), radius=3, fill=(30, 40, 55, 255), outline=(180, 200, 220, 255), width=1)
d.rounded_rectangle((78 + 3 * 28, 145, 78 + 3 * 28 + 18, 168), radius=3, fill=(200, 140, 40, 255))
for i in range(4):
	d.ellipse((82 + i * 28, 130, 92 + i * 28, 140), fill=(80, 230, 120, 255))
save(im, "icon_router.png")

# --- Switch ---
im = new_img()
d = ImageDraw.Draw(im)
body = (36, 100, 220, 176)
shadow(d, body, 10)
round_rect(d, body, 10, (55, 170, 95, 255), (140, 230, 160, 255), 3)
for row in range(2):
	for col in range(8):
		x = 50 + col * 20
		y = 118 + row * 24
		d.rounded_rectangle((x, y, x + 14, y + 16), radius=2, fill=(25, 35, 45, 255), outline=(200, 220, 210, 255), width=1)
d.rectangle((28, 118, 40, 158), fill=(90, 100, 110, 255))
d.rectangle((216, 118, 228, 158), fill=(90, 100, 110, 255))
save(im, "icon_switch.png")

# --- Access Point ---
im = new_img()
d = ImageDraw.Draw(im)
d.ellipse((72, 94, 192, 214), fill=(0, 0, 0, 70))
d.ellipse((64, 80, 192, 208), fill=(150, 95, 210, 255), outline=(210, 170, 255, 255), width=3)
d.ellipse((88, 104, 168, 184), fill=(95, 55, 145, 255))
for r in (78, 98, 118):
	bbox = (CX - r, CY - r - 10, CX + r, CY + r - 10)
	d.arc(bbox, 210, 330, fill=(230, 210, 255, 220), width=6)
d.ellipse((CX - 10, CY - 6, CX + 10, CY + 14), fill=(120, 240, 180, 255))
d.rounded_rectangle((118, 198, 138, 222), radius=3, fill=(40, 45, 60, 255), outline=(200, 210, 230, 255), width=1)
save(im, "icon_ap.png")

# --- PC ---
im = new_img()
d = ImageDraw.Draw(im)
mon = (70, 48, 186, 140)
shadow(d, (74, 54, 190, 146), 8)
round_rect(d, mon, 8, (90, 120, 170, 255), (180, 205, 240, 255), 3)
d.rounded_rectangle((82, 60, 174, 120), radius=4, fill=(30, 50, 80, 255))
d.rectangle((118, 140, 138, 158), fill=(120, 130, 145, 255))
d.rounded_rectangle((98, 156, 158, 168), radius=4, fill=(100, 110, 125, 255))
tower = (168, 100, 214, 198)
shadow(d, (172, 106, 218, 204), 6)
round_rect(d, tower, 6, (70, 95, 140, 255), (160, 190, 230, 255), 2)
for i in range(4):
	y = 118 + i * 16
	d.rectangle((178, y, 204, y + 8), fill=(40, 50, 70, 255))
d.ellipse((184, 182, 198, 196), fill=(80, 220, 120, 255))
d.ellipse((86, 178, 112, 198), fill=(110, 130, 160, 255), outline=(190, 210, 235, 255), width=1)
save(im, "icon_pc.png")

print("done")
