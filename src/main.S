INCLUDE "hardware.inc"

SECTION "Header", ROM0[$100]
	jp Entry

	ds $150 - @, 0 ; Skip space for header

Entry:
	call AwaitVBlank ; wait until valid state
	
	ld a, 0
	ld [rLCDC], a ; turn off LCD

	; load tiles
	ld de, Tiles
	ld hl, $9000
	ld bc, TilesEnd - Tiles
	call Memcopy

	; load tilemap
	ld de, Tilemap
	ld hl, $9800
	ld bc, TilemapEnd - Tilemap
	call Memcopy

	ld a, 0
	ld b, 160
	ld hl, _OAMRAM
	call Memset ; clear object memory

	; load paddle object
	ld hl, _OAMRAM
	ld a, 128 + 16
	ld [hl+], a ; set y
	ld a, 16 + 8
	ld [hl+], a ; set x
	ld a, 0
	ld [hl+], a ; set id
	ld [hl], a ; set attributes
	; load paddle tile
	ld de, Paddle
	ld hl, $8000
	ld bc, PaddleEnd - Paddle
	call Memcopy

	ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON
	ld [rLCDC], a

	ld a, %11_10_01_00
	ld [rBGP], a

	; init variables
	ld a, 0
	ld [curKeys], a
	ld [newKeys], a

Main:
	call AwaitNotVBlank
	call AwaitVBlank ; wait for next vblank, not using the same vblank??

	call PollInput

LeftPressed:
	ld a, [curKeys]
	and a, PADF_LEFT
	jp z, RightPressed
		ld a, [_OAMRAM + 1]
		dec a
		cp a, 15 ; limit movement
		jp z, MainEnd
		ld [_OAMRAM + 1], a
		jp MainEnd

RightPressed:
	ld a, [curKeys]
	and a, PADF_RIGHT
	jp z, MainEnd
		ld a, [_OAMRAM + 1]
		inc a
		cp a, 105 ; limit movement
		jp z, MainEnd
		ld [_OAMRAM + 1], a

MainEnd:
	jp Main

Park: jp Park

AwaitVBlank:
	ld a, [rLY]
	cp 144
	jp c, AwaitVBlank
	ret

AwaitNotVBlank:
	ld a, [rLY]
	cp 144
	jp nc, AwaitNotVBlank
	ret

; de = src, hl = dst, bc = len
Memcopy:
	ld a, [de]
	ld [hli], a
	inc de
	dec bc
	ld a, b
	or a, c
	jp nz, Memcopy
	ret

; a = val, b = len, hl = src
Memset:
	ld [hl+], a
	dec b
	jp nz, Memset
	ret

PollInput: ; author decided readers are stupid so idk how this works yet
	ld a, P1F_GET_BTN
	call .onenibble
	ld b, a
	ld a, P1F_GET_DPAD
	call .onenibble
	swap a
	xor a, b
	ld b, a
	ld a, P1F_GET_NONE
	ldh [rP1], a
	ld a, [curKeys]
	xor a, b
	and a, b
	ld [newKeys], a
	ld a, b
	ld [curKeys], a
	ret

.onenibble
	ldh [rP1], a
	call .knownret
	ldh a, [rP1]
	ldh a, [rP1]
	ldh a, [rP1]
	or a, $F0
.knownret
	ret

SECTION "Input", WRAM0
curKeys: db
newKeys: db
