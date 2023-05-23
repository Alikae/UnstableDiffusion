extends HBoxContainer


func init(label, img1, img2):
	$Label.text = label
	$TextureRect.texture = ImageTexture.create_from_image(img1)
	$TextureRect2.texture = ImageTexture.create_from_image(img2)
