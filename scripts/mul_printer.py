import re

inss = ["bn.mulqacc.z          w8.0, w10.0,   0",
  "bn.mulqacc            w8.0, w10.1,  64",
  "bn.mulqacc.so w16.L,  w8.1, w10.0,  64",
  "bn.mulqacc            w8.0, w10.2,   0",
  "bn.mulqacc            w8.1, w10.1,   0",
  "bn.mulqacc            w8.2, w10.0,   0",
  "bn.mulqacc            w8.0, w10.3,  64",
  "bn.mulqacc            w8.1, w10.2,  64",
  "bn.mulqacc            w8.2, w10.1,  64",
  "bn.mulqacc.so w16.U,  w8.3, w10.0,  64",
  "bn.mulqacc            w8.0, w11.0,   0",
  "bn.mulqacc            w8.1, w10.3,   0",
  "bn.mulqacc            w8.2, w10.2,   0",
  "bn.mulqacc            w8.3, w10.1,   0",
  "bn.mulqacc            w9.0, w10.0,   0",
  "bn.mulqacc            w8.0, w11.1,  64",
  "bn.mulqacc            w8.1, w11.0,  64",
  "bn.mulqacc            w8.2, w10.3,  64",
  "bn.mulqacc            w8.3, w10.2,  64",
  "bn.mulqacc            w9.0, w10.1,  64",
  "bn.mulqacc.so w17.L,  w9.1, w10.0,  64",
  "bn.mulqacc            w8.1, w11.1,   0",
  "bn.mulqacc            w8.2, w11.0,   0",
  "bn.mulqacc            w8.3, w10.3,   0",
  "bn.mulqacc            w9.0, w10.2,   0",
  "bn.mulqacc            w9.1, w10.1,   0",
  "bn.mulqacc            w8.2, w11.1,  64",
  "bn.mulqacc            w8.3, w11.0,  64",
  "bn.mulqacc            w9.0, w10.3,  64",
  "bn.mulqacc.so w17.U,  w9.1, w10.2,  64",
  "bn.mulqacc            w8.3, w11.1,   0",
  "bn.mulqacc            w9.0, w11.0,   0",
  "bn.mulqacc            w9.1, w10.3,   0",
  "bn.mulqacc            w9.0, w11.1,  64",
  "bn.mulqacc.so w18.L,  w9.1, w11.0,  64",
  "bn.mulqacc.so w18.U,  w9.1, w11.1,   0"]

qsel = re.compile("(w[0-9]+).([0-3])")

def get_qsel(s):
    m = re.match(qsel, s)
    return m.groups(0)

def get_shift(s):
    if s == "0":
        return "0"
    if s == "64":
        return "1"
    assert False
    
so = re.compile("(w[0-9]+).(L|U)")

def get_so(s):
    m = re.match(so, s)
    w, h = m.groups(0)
    lower = "false"
    if h == "L":
        lower = "true"
    return (w, lower)

for ins in inss:
    ins = re.split("\s+", ins)
    op = ins[0]
    if op == "bn.mulqacc.z":
        x, qx = get_qsel(ins[1])
        y, qy = get_qsel(ins[2])
        shift = get_shift(ins[3])
        print(f"BN_MULQACC_Z({x}, {qx}, {y}, {qy}, {shift});")
    elif op == "bn.mulqacc":
        x, qx = get_qsel(ins[1])
        y, qy = get_qsel(ins[2])
        shift = get_shift(ins[3])
        print(f"BN_MULQACC_SAFE({x}, {qx}, {y}, {qy}, {shift});")
    else:
        assert op == "bn.mulqacc.so"
        d, l = get_so(ins[1])

        x, qx = get_qsel(ins[2])
        y, qy = get_qsel(ins[3])
        shift = get_shift(ins[4])

        print(f"BN_MULQACC_SO_SAFE({d}, {l}, {x}, {qx}, {y}, {qy}, {shift});")
