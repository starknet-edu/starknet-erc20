import subprocess, json
from utils import str_to_felt, felt_to_str

# essential settings
network = "devnet"
account_addr = "0x33507ff2edf12c12c73d0b6d1d90de9fac12a355de1097ab305249612451919"
salt = 1234
tutoerc20_addr = "0x"
player_registry_addr = "0x"
dummytoken_addr = "0x"
evaluator_addr = "0x"
pkey = ".pkey"
max_fee = "auto"

def run_command(cmd):
  out = subprocess.check_output(cmd.split(" "))
  return out.decode("utf-8")

def install():
  print("Installing OpenZeppelin/cairo-contracts...")
  run_command("protostar install OpenZeppelin/cairo-contracts@v0.6.0")
  return

# Build
def build(cairo_path):
  print("BUILDing...")
  run_command(f"protostar build --cairo-path {cairo_path}")
  return

# Test
def test():
  print("Testing...")
  run_command("protostar test")
  return

# Deploy Players Registry
def deploy_players_registry():
  contract = "players_registry"
  print("DECLARE " + contract)
  out = run_command(f"protostar -p {network} declare ./build/{contract}.json --account-address {account_addr} --private-key-path ./{pkey} --max-fee {max_fee} --json")

  print("DEPLOY " + contract)
  class_hash = json.loads(out)['class_hash']
  out = run_command(f"protostar -p {network} deploy {class_hash} --salt {salt} --account-address {account_addr} --private-key-path ./{pkey} --max-fee {max_fee} -i {account_addr} --json")

  global player_registry_addr
  player_registry_addr = json.loads(out)['contract_address']
  print("player_registry_addr: " + player_registry_addr)
  return

# Deploy TDERC20
def deploy_tutoerc20(token_name_str, token_symbol_str):
  contract = "TUTOERC20"
  print("DECLARE " + contract)
  out = run_command(f"protostar -p {network} declare ./build/{contract}.json --account-address {account_addr} --private-key-path ./{pkey} --max-fee {max_fee} --json")

  print("DEPLOY " + contract)
  token_name = str_to_felt(token_name_str)
  token_symbol = str_to_felt(token_symbol_str)
  class_hash = json.loads(out)['class_hash']
  out = run_command(f"protostar -p {network} deploy {class_hash} --salt {salt} --account-address {account_addr} --private-key-path ./{pkey} --max-fee {max_fee} -i {token_name} {token_symbol} 0 0 {account_addr} {account_addr} --json")

  global tderc20_addr
  tderc20_addr = json.loads(out)['contract_address']
  print("tderc20_addr: " + tderc20_addr)
  return

# Deploy Dummy Token
def deploy_dummy_token(token_name_str, token_symbol_str):
  contract = "dummy_token"
  print("DECLARE " + contract)
  out = run_command(f"protostar -p {network} declare ./build/{contract}.json --account-address {account_addr} --private-key-path ./{pkey} --max-fee {max_fee} --json")

  print("DEPLOY " + contract)
  token_name = str_to_felt(token_name_str)
  token_symbol = str_to_felt(token_symbol_str)
  class_hash = json.loads(out)['class_hash']
  out = run_command(f"protostar -p {network} deploy {class_hash} --salt {salt} --account-address {account_addr} --private-key-path ./{pkey} --max-fee {max_fee} -i {token_name} {token_symbol} 100000000000000000000 0 {account_addr} --json")

  global dummytoken_addr
  dummytoken_addr = json.loads(out)['contract_address']
  print("dummytoken_addr: " + dummytoken_addr)
  return

# Deploy Evaluator
def deploy_evaluator():
  contract = "Evaluator"
  print("DECLARE " + contract)
  out = run_command(f"protostar -p {network} declare ./build/{contract}.json --account-address {account_addr} --private-key-path ./{pkey} --max-fee {max_fee} --json")

  print("DEPLOY " + contract)
  class_hash = json.loads(out)['class_hash']
  out = run_command(f"protostar -p {network} deploy {class_hash} --salt {salt} --account-address {account_addr} --private-key-path ./{pkey} --max-fee {max_fee} -i {player_registry_addr} {tderc20_addr} {dummytoken_addr} 2 {account_addr} --json")

  global evaluator_addr
  evaluator_addr = json.loads(out)['contract_address']
  print("evaluator_addr: " + evaluator_addr)
  return

# Evaluator set_random_values
def evaluator_set_random_values(list_length, list, column):
  contract = "Evaluator"
  print("Invoke set_random_values on " + contract + " for column " + str(column))
  list_string = ' '.join(str(e) for e in list)
  run_command(f"protostar -p {network} invoke --contract-address {evaluator_addr} --function set_random_values --account-address {account_addr} --inputs {list_length} {list_string} {column} --private-key-path ./{pkey} --max-fee {max_fee} --json")
  return

# Set Evaluator as admin in ERC20
def set_evaluator_admin():
  print("set admin and teacher for Evaluator")
  run_command(f"protostar -p {network} invoke --contract-address {tderc20_addr} --function set_teacher --account-address {account_addr} --inputs {evaluator_addr} 1 --max-fee {max_fee} --private-key-path ./{pkey} --json")
  run_command(f"protostar -p {network} invoke --contract-address {player_registry_addr} --function set_exercise_or_admin --account-address {account_addr} --inputs {evaluator_addr} 1 --max-fee {max_fee} --private-key-path ./{pkey} --json")

  return

def print_all_contracts():
  print(f"Yo starknet fans, all contracts deployed successfully on {network}!")
  print("=================================================================================")
  print("tderc20_addr: ", tderc20_addr)
  print("player_registry_addr: ", tderc20_addr)
  print("dummytoken_addr: ", dummytoken_addr)
  print("evaluator_addr: ", evaluator_addr)
  print("=================================================================================")
  return

def deploy_all():
  #install()
  build('./lib/cairo_contracts/src')
  # test()
  deploy_players_registry()
  deploy_tutoerc20("ERC20-101", "ERC20-101")
  deploy_dummy_token("DummyToken-ERC20", "DTK20")
  deploy_evaluator()
  evaluator_set_random_values(100, [1146045253,1246123597,1095194946,1229539148,1146378315,1447972440,1380930885,1481919816,1514423620,1380865093,1447970121,1347639363,1313424714,1314149714,1314282072,1514358355,1481263182,1146178124,1213156683,1129270861,1514623319,1515081808,1331315536,1229672001,1111704643,1230651986,1380731732,1162824782,1296586325,1112163394,1498369876,1246844240,1481984340,1111641942,1196639555,1280789843,1196051542,1514494545,1297763154,1481919820,1313362001,1095586649,1431589459,1313754188,1096174913,1262765395,1196578885,1431062350,1245924184,1498497603,1263229530,1313559621,1096239194,1096112194,1380800078,1112688714,1163480154,1296519509,1465404249,1263224399,1380271447,1296191831,1279677518,1431785299,1180191310,1129989449,1297634636,1363957319,1380666188,1380996691,1346586457,1415136583,1363299162,1280070481,1246843724,1331123524,1380995159,1497846082,1263554369,1146504773,1162037337,1095453511,1447712589,1213091650,1229670221,1297238857,1431328854,1515017289,1230133831,1195526998,1346521154,1280464705,1431849558,1230262872,1095648083,1413761609,1162824514,1331057752,1262637655,1145130563], 0)
  evaluator_set_random_values(100, [5700000000000000000000,7800000000000000000000,6700000000000000000000,56000000000000000000000,13000000000000000000000,930000000000000000000,80000000000000000000,450000000000000000000,95000000000000000000000,6100000000000000000000,25000000000000000000000,700000000000000000000,93000000000000000000000,89000000000000000000000,360000000000000000000,37000000000000000000000,410000000000000000000,470000000000000000000,2000000000000000000000,84000000000000000000000,160000000000000000000,64000000000000000000000,4000000000000000000000,400000000000000000000,100000000000000000000000,810000000000000000000,93000000000000000000000,410000000000000000000,3900000000000000000000,30000000000000000000,8800000000000000000000,91000000000000000000000,83000000000000000000000,5000000000000000000000,74000000000000000000000,62000000000000000000000,8800000000000000000000,4900000000000000000000,430000000000000000000,41000000000000000000000,950000000000000000000,9300000000000000000000,95000000000000000000000,100000000000000000000,990000000000000000000,9600000000000000000000,280000000000000000000,4400000000000000000000,130000000000000000000,88000000000000000000000,64000000000000000000000,2900000000000000000000,6900000000000000000000,830000000000000000000,850000000000000000000,80000000000000000000,1800000000000000000000,570000000000000000000,450000000000000000000,3700000000000000000000,800000000000000000000,8400000000000000000000,9100000000000000000000,4200000000000000000000,29000000000000000000000,600000000000000000000,77000000000000000000000,33000000000000000000000,6200000000000000000000,91000000000000000000000,37000000000000000000000,960000000000000000000,17000000000000000000000,9100000000000000000000,140000000000000000000,90000000000000000000000,9800000000000000000000,6800000000000000000000,8200000000000000000000,96000000000000000000000,36000000000000000000000,760000000000000000000,52000000000000000000000,8800000000000000000000,570000000000000000000,72000000000000000000000,1400000000000000000000,720000000000000000000,9800000000000000000000,60000000000000000000,1400000000000000000000,2200000000000000000000,770000000000000000000,5900000000000000000000,66000000000000000000000,5600000000000000000000,620000000000000000000,770000000000000000000,5800000000000000000000,160000000000000000000],1)
  set_evaluator_admin()
  print_all_contracts()

deploy_all()