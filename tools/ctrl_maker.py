with open('global.txt') as f:
	lines = f.readlines()
	title = lines[0].split()
	items = [x.split() for x in lines[1:]]

preq = title[0].count('/')
bits = title[0].count('-')

def gini(d):
	s = set(v for k, v in d)
	g = 1
	for i in s:
		g -= (sum(1 for k, v in d if v == i) / len(d)) ** 2
	return g

def readable_and(s, t):
	if(len(t) == 0):
		return s
	return s + ' & ' + t

def readable_merge(d0, d1, i):
	d = d0 | d1
	for k in d:
		if(k not in d0):
			d[k] = readable_and('[{}]'.format(i), d1[k])
		elif(k not in d1):
			d[k] = readable_and('~[{}]'.format(i), d0[k])
		else:
			d[k] = '({} | {})'.format(readable_and('~[{}]'.format(i), d0[k]), readable_and('[{}]'.format(i), d1[k]))
	return d

def solve(d, mask = 0):
	if(len(d) == 0):
		return {}
	s = set(v for k, v in d)
	if(len(s) == 1):
		return {s.pop(): ''}
	min_gini = -1
	min_idx = -1
	for i in range(0, bits):
		if(mask & 1 << i):
			continue
		s0 = [(k, v) for k, v in d if k[i] == '0']
		s1 = [(k, v) for k, v in d if k[i] == '1']
		if(len(s0) + len(s1) != len(d) or len(s0) == 0 or len(s1) == 0):
			continue
		g = gini(s0) * len(s0) / len(d) + gini(s1) * len(s1) / len(d)
		if(min_idx == -1 or g < min_gini):
			min_gini = g
			min_idx = i
	if(min_idx == -1):
		raise "fuck"
	s0 = [(k, v) for k, v in d if k[min_idx] == '0']
	s1 = [(k, v) for k, v in d if k[min_idx] == '1']
	return readable_merge(solve(s0, mask | 1 << min_idx), solve(s1, mask | 1 << min_idx), bits - 1 - min_idx)

for i in range(1, len(title)):
	print(title[i])
	ans = solve([(item[0][preq:], item[i]) for item in items if item[i] != '?'])
	kind = set(item[i] for item in items if item[i] != '?')
	if(len(kind) == 4):
		print(4)
	print(ans)
