OUT = build/rom.gb

OBJS := src/main.o

%.o: %.S
	rgbasm -o $@ $<

$(OUT): $(OBJS)
	@mkdir -p build
	@rgblink -o $(OUT) $(OBJS)
	@rgbfix -v -p 0xFF $(OUT)

.PHONY: clean
clean: $(OUT)
	rm -rf $(OUT) $(OBJS)

.PHONY: run
run: $(OUT)
	@cp $(OUT) /sdcard/Download/MyOldBoy
