lui a1, 0xA
addi a1, a1, 0x10

lui a2, 0xA



come:
lb t1, a1, 0	
sb a2, t1, 0	
jal zero, come	