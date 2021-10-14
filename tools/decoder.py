table = [
	# ('000000000000000000000?????001111', 'SYNC'),
	# ('00000000000???????????????000000', 'SLL'),
	# ('00000000000???????????????000010', 'SRL'),
	# ('00000000000???????????????000011', 'SRA'),
	# ('000000???????????????00000000100', 'SLLV'),
	# ('000000???????????????00000000110', 'SRLV'),
	# ('000000???????????????00000000111', 'SRAV'),
	# ('000000???????????????00000001010', 'MOVZ'),
	# ('000000???????????????00000001011', 'MOVN'),
	# ('000000?????000000000000000001000', 'JR'),
	# ('000000?????00000?????00000001001', 'JALR'),
	# ('000000????????????????????001100', 'SYSCALL'),
	# ('000000????????????????????001101', 'BREAK'),
	# ('0000000000000000?????00000010000', 'MFHI'),
	# ('000000?????000000000000000010001', 'MTHI'),
	# ('0000000000000000?????00000010010', 'MFLO'),
	# ('000000?????000000000000000010011', 'MTLO'),
	# ('000000??????????0000000000011000', 'MULT'),
	# ('000000??????????0000000000011001', 'MULTU'),
	# ('000000??????????0000000000011010', 'DIV'),
	# ('000000??????????0000000000011011', 'DIVU'),
	# ('000000???????????????00000100000', 'ADD'),
	# ('000000???????????????00000100001', 'ADDU'),
	# ('000000???????????????00000100010', 'SUB'),
	# ('000000???????????????00000100011', 'SUBU'),
	# ('000000???????????????00000100100', 'AND'),
	# ('000000???????????????00000100101', 'OR'),
	# ('000000???????????????00000100110', 'XOR'),
	# ('000000???????????????00000100111', 'NOR'),
	# ('000000???????????????00000101010', 'SLT'),
	# ('000000???????????????00000101011', 'SLTU'),
	('000000????????????????????110000', 'TGE'),
	('000000????????????????????110001', 'TGEU'),
	('000000????????????????????110010', 'TLT'),
	('000000????????????????????110011', 'TLTU'),
	('000000????????????????????110100', 'TEQ'),
	('000000????????????????????110110', 'TNE'),
	# ('000001?????00000????????????????', 'BLTZ'),
	# ('000001?????00001????????????????', 'BGEZ'),
	('000001?????01000????????????????', 'TGEI'),
	('000001?????01001????????????????', 'TGEIU'),
	('000001?????01010????????????????', 'TLTI'),
	('000001?????01011????????????????', 'TLTIU'),
	('000001?????01110????????????????', 'TNEI'),
	('000001?????01100????????????????', 'TEQI'),
	# ('000001?????10000????????????????', 'BLTZAL'),
	# ('000001?????10001????????????????', 'BGEZAL'),
	# ('000010??????????????????????????', 'J'),
	# ('000011??????????????????????????', 'JAL'),
	# ('000100??????????????????????????', 'BEQ'),
	# ('000101??????????????????????????', 'BNE'),
	# ('000110?????00000????????????????', 'BLEZ'),
	# ('000111?????00000????????????????', 'BGTZ'),
	# ('001000??????????????????????????', 'ADDI'),
	# ('001001??????????????????????????', 'ADDIU'),
	# ('001010??????????????????????????', 'SLTI'),
	# ('001011??????????????????????????', 'SLTIU'),
	# ('001100??????????????????????????', 'ANDI'),
	# ('001101??????????????????????????', 'ORI'),
	# ('001110??????????????????????????', 'XORI'),
	# ('00111100000?????????????????????', 'LUI'),
	# ('01000000000??????????00000000???', 'MFC0'),
	# ('01000000100??????????00000000???', 'MTC0'),
	# ('01000010000000000000000000000001', 'TLBR'),
	# ('01000010000000000000000000000010', 'TLBWI'),
	# ('01000010000000000000000000000110', 'TLBWR'),
	# ('01000010000000000000000000001000', 'TLBP'),
	# ('01000010000000000000000000011000', 'ERET'),
	# ('011100??????????0000000000000000', 'MADD'),
	# ('011100??????????0000000000000001', 'MADDU'),
	# ('011100??????????0000000000000100', 'MSUB'),
	# ('011100??????????0000000000000101', 'MSUBU'),
	# ('011100???????????????00000000010', 'MUL'),
	# ('100000??????????????????????????', 'LB'),
	# ('100001??????????????????????????', 'LH'),
	# ('100010??????????????????????????', 'LWL'),
	# ('100011??????????????????????????', 'LW'),
	# ('100100??????????????????????????', 'LBU'),
	# ('100101??????????????????????????', 'LHU'),
	# ('100110??????????????????????????', 'LWR'),
	# ('101000??????????????????????????', 'SB'),
	# ('101001??????????????????????????', 'SH'),
	# ('101010??????????????????????????', 'SWL'),
	# ('101011??????????????????????????', 'SW'),
	# ('101110??????????????????????????', 'SWR'),
	# ('101111??????????????????????????', 'CACHE'),
	# ('110011??????????????????????????', 'PREF'),
]

class Boolean:
	def __init__(self, x):
		self.x = {'0': -1, '?': 0, '1': 1}.get(x, x)

	def __and__(self, other):
		return Boolean(min(self.x, other.x))

	def __or__(self, other):
		return Boolean(max(self.x, other.x))

	def __invert__(self):
		return Boolean(-self.x)

	def __repr__(self):
		return {-1: '0', 0: 'x', 1: '1'}[self.x]

for inst, name in table:
	inst = list(Boolean(x) for x in inst[::-1])
	print('=====', name, '=====')
	ctrl = {}

	ctrl['BJRJ'] = ~inst[26] & (~inst[27] & (~inst[28] & ~inst[30] & ~inst[31] & ~inst[29] & inst[3] & ~inst[1] & ~inst[4] & ~inst[2] | inst[28] & ~inst[29] & ~inst[31]) | inst[27] & ~inst[31] & ~inst[29]) | inst[26] & ~inst[31] & ~inst[29] & (~inst[19] | inst[27] | inst[28])
	ctrl['B']    = ~inst[26] & inst[28] & ~inst[29] & ~inst[31] | inst[26] & ~inst[31] & ~inst[29] & (~inst[27] & ~inst[19] | inst[28])
	ctrl['JR']   = ~inst[31] & ~inst[30] & ~inst[29] & ~inst[28] & ~inst[27] & ~inst[26] & ~inst[4] & inst[3] & ~inst[2] & ~inst[1]
	ctrl['J']    = ~inst[31] & ~inst[29] & ~inst[28] & inst[27]

	ctrl['PRV'] = ~inst[31] & inst[30] & ~inst[29]

	ctrl['SYSCALL'] = ~inst[31] & ~inst[30] & ~inst[29] & ~inst[28] & ~inst[27] & ~inst[26] & inst[3] & inst[2] & ~inst[0]
	ctrl['BREAK']   = ~inst[31] & ~inst[30] & ~inst[29] & ~inst[28] & ~inst[27] & ~inst[26] & inst[3] & inst[2] & ~inst[1] & inst[0]
	ctrl['ERET']    = ~inst[31] & inst[30] & inst[4]
	ctrl['OFA']     = ~inst[26] & ~inst[30] & (~inst[29] & ~inst[31] & ~inst[28] & ~inst[27] & inst[5] & ~inst[0] & ~inst[4] & ~inst[2] & ~inst[3] | inst[29] & ~inst[27] & ~inst[31] & ~inst[28])

	ctrl['ES'] = ~inst[30] & (~inst[28] & ~inst[27] & (~inst[26] & (~inst[3] & inst[2] | inst[3] & (inst[1] | inst[4]) | inst[5]) | inst[26] & inst[19]) | inst[31]) | inst[29]
	ctrl['ET'] = ~inst[26] & ~inst[27] & ~inst[31] & (~inst[30] & ~inst[29] & ~inst[28] & (~inst[3] & ~inst[4] | inst[3] & inst[4] | inst[5]) | inst[30] & inst[29])
	ctrl['DS'] = ~inst[26] & (~inst[28] & ~inst[30] & ~inst[31] & ~inst[29] & ~inst[27] & inst[3] & ~inst[1] & ~inst[4] & ~inst[2] | inst[28] & ~inst[29] & ~inst[31]) | inst[26] & ~inst[31] & ~inst[29] & (~inst[27] & ~inst[19] | inst[28])
	ctrl['DT'] = ~inst[28] & ~inst[26] & ~inst[30] & ~inst[31] & ~inst[29] & ~inst[27] & inst[3] & inst[1] & ~inst[5] & ~inst[4] | inst[28] & ~inst[29] & ~inst[31] & ~inst[27]

	ctrl['DP0'] = ~inst[31] & (~inst[30] & (~inst[26] & (~inst[4] | ~inst[5] | inst[27] | inst[28]) | inst[26] & (~inst[19] | inst[27] | inst[28])) | inst[30] & (~inst[25] | inst[4]) | inst[29]) | inst[31] & inst[30]
	ctrl['DP1'] = ~inst[30] & (~inst[4] | inst[5] | inst[28] | inst[29] | inst[31] | inst[27] | inst[26]) | inst[30] & ~inst[29] & (inst[25] | inst[31])

	ctrl['ECtrl_OP_f_sl']   = ~inst[31] & ~inst[29] & ~inst[28] & ~inst[27] & ~inst[26] & ~inst[5] & ~inst[3] & ~inst[1]
	ctrl['ECtrl_OP_f_sr']   = ~inst[31] & ~inst[28] & ~inst[26] & ~inst[27] & ~inst[29] & ~inst[5] & ~inst[3] & inst[1]
	ctrl['ECtrl_OP_f_add']  = ~inst[28] & (~inst[26] & ~inst[27] & ((~inst[5] & inst[3] & ~inst[1] | inst[5] & (~inst[0] & (~inst[2] & ~inst[4] & ~inst[3] | inst[2] & inst[4]) | inst[0] & ~inst[2] & ~inst[4] & ~inst[3])) | inst[29]) | inst[26] & (~inst[29] & ((~inst[16] & (inst[20] | inst[18]) | inst[16] & inst[20]) | inst[27]) | inst[29] & ~inst[27])) | inst[31]
	ctrl['ECtrl_OP_f_and']  = ~inst[31] & (~inst[28] & ~inst[26] & ~inst[27] & ~inst[29] & inst[5] & ~inst[0] & inst[2] & ~inst[4] & ~inst[1] | inst[28] & ~inst[27] & ~inst[26])
	ctrl['ECtrl_OP_f_or']   = ~inst[31] & (~inst[29] & ~inst[28] & ~inst[27] & ~inst[26] & inst[5] & inst[2] & inst[0] | inst[28] & ~inst[27] & inst[26])
	ctrl['ECtrl_OP_f_xor']  = ~inst[31] & (~inst[28] & ~inst[26] & ~inst[27] & ~inst[29] & inst[5] & ~inst[0] & inst[2] & ~inst[4] & inst[1] | inst[28] & inst[27])
	ctrl['ECtrl_OP_f_slt']  = ~inst[31] & ~inst[28] & (~inst[26] & (~inst[29] & inst[5] & ~inst[0] & ~inst[2] & (inst[3] | inst[4]) | inst[27]) | inst[26] & ~inst[29] & ~inst[27] & ~inst[16] & ~inst[18] & ~inst[20])
	ctrl['ECtrl_OP_f_sltu'] = ~inst[31] & ~inst[28] & (~inst[26] & ~inst[27] & ~inst[29] & inst[5] & inst[0] & ~inst[2] & (inst[3] | inst[4]) | inst[26] & (~inst[29] & ~inst[27] & inst[16] & ~inst[20] | inst[29] & inst[27]))
	ctrl['ECtrl_OP_f_mova'] = ~inst[31] & ~inst[29] & ~inst[28] & ~inst[27] & ~inst[26] & ~inst[5] & inst[3] & inst[1]
	ctrl['ECtrl_OP_alt']    = ~inst[31] & ~inst[28] & (~inst[29] & ~inst[27] & (~inst[26] & (inst[1] & (inst[0] | inst[5]) | inst[4]) | inst[26] & ~inst[20]) | inst[29] & inst[27])

	ctrl['ECtrl_SA'] = ((~inst[27] & (~inst[26] & ((inst[3] & inst[1] | inst[2]) | inst[5]) | inst[26] & ~inst[20]) | inst[31]) | inst[29], (~inst[28] & (inst[2] | inst[3] | inst[5] | inst[29] | inst[26]) | inst[28] & (~inst[27] | ~inst[26])) | inst[31])
	ctrl['ECtrl_SB'] = ((inst[26] & ~inst[27] & ~inst[20] | inst[31]) | inst[29], inst[3] & ~inst[5] | inst[26])
	ctrl['imm']      = (~inst[31] & inst[28] & inst[27] & inst[26], inst[31] | ~inst[28])

	ctrl['MCtrl0_HW']  = ~inst[30] & ~inst[26] & ~inst[29] & ~inst[28] & ~inst[27] & inst[4] & (~inst[5] & ~inst[1] & inst[0] | inst[3]) | inst[30] & inst[29] & ~inst[1]
	ctrl['MCtrl0_LW']  = ~inst[30] & ~inst[26] & ~inst[29] & ~inst[28] & ~inst[27] & inst[4] & (~inst[5] & inst[1] & inst[0] | inst[3]) | inst[30] & inst[29] & ~inst[1]
	ctrl['MCtrl0_HLS'] = (~inst[30] & ~inst[26] & ~inst[27] & ~inst[31] & ~inst[29] & ~inst[28] & inst[4] & inst[3] | inst[30] & inst[29]), inst[1] & ~inst[30], inst[0]
	ctrl['MCtrl0_MAS'] = (inst[2], inst[30] & ~inst[2] & ~inst[1])
	ctrl['MCtrl0_C0W'] = ~inst[31] & inst[30] & ~inst[29] & inst[23] & ~inst[3]
	ctrl['MCtrl0_RS0'] = (~inst[30] & (~inst[4] | inst[5] | inst[29] | inst[26]), inst[30], ~inst[29] & (~inst[1] | inst[30]))

	ctrl['MCtrl1_MR']       = inst[31] & ~inst[30]
	ctrl['MCtrl1_MWR']      = inst[29]
	ctrl['MCtrl1_MX']       = ~inst[28]
	ctrl['MCtrl1_ALR']      = (inst[28] & inst[27] & ~inst[26], ~inst[28] & inst[27] & ~inst[26])
	ctrl['MCtrl1_TLBR']     = ~inst[31] & inst[30] & ~inst[29] & inst[25] & ~inst[3] & ~inst[1]
	ctrl['MCtrl1_TLBWI']    = ~inst[31] & inst[30] & ~inst[29] & inst[25] & ~inst[3] & inst[1]
	ctrl['MCtrl1_TLBWR']    = ~inst[31] & inst[30] & ~inst[29] & inst[25] & ~inst[3] & (inst[2] | ~inst[1])
	ctrl['MCtrl1_TLBP']     = ~inst[31] & inst[30] & ~inst[4] & inst[3]
	ctrl['MCtrl1_CACHE_OP'] = (inst[29] & inst[28] & inst[26] & inst[16], inst[29] & inst[28] & inst[26] & ~inst[20], inst[29] & inst[28] & inst[26] & ~inst[18] & (inst[20] | inst[19] | ~inst[16]))

	ctrl['Trap_TEN'] = ~inst[30] & ~inst[27] & (~inst[26] & ~inst[31] & ~inst[29] & ~inst[28] & inst[4] & inst[5] | inst[26] & ~inst[31] & ~inst[29] & ~inst[28] & inst[19]) | inst[30] & ~inst[29] & ~inst[31]
	ctrl['Trap_OP']  = (~inst[26] & inst[2] | inst[26] & inst[18], ~inst[26] & inst[1] | inst[26] & inst[17])

	ctrl['WCtrl_MOV'] = ~inst[31] & ~inst[30] & ~inst[29] & ~inst[28] & ~inst[27] & ~inst[26] & ~inst[5] & ~inst[4] & inst[3] & ~inst[2] & inst[1]
	ctrl['WCtrl_RW']  = ~inst[30] & (~inst[26] & (~inst[27] & (~inst[31] & (~inst[28] & (~inst[4] & (~inst[3] | ~inst[2] & (inst[0] | inst[1])) | inst[4] & ~inst[5] & ~inst[3] & ~inst[0]) | inst[29]) | inst[31] & ~inst[29]) | inst[27] & (~inst[31] & inst[29] | inst[31] & ~inst[29])) | inst[26] & (~inst[29] & (~inst[27] & ~inst[28] & inst[20] | inst[27] & ~inst[28] | inst[31]) | inst[29] & ~inst[31])) | inst[30] & ~inst[31] & ~inst[3] & (~inst[29] & ~inst[25] & ~inst[23] | inst[29] & inst[1])
	ctrl['RD']        = (~inst[29] & inst[30] | inst[29] & ~inst[30] | inst[31], inst[26])
	print(ctrl)
