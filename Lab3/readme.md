일단은 원래 주어진거 top.v랑 cpu.v랑 Memory.v랑 RegisterFile.v임
그중에 Memory랑 RegisterFile은 완성본 주어짐

그래가지고 sangy00n 소스랑 예전에 싱사시 한거 보면서
PC 모듈을 PC.v에, ALU 모듈을 alu.v에, Immgeneratro 모듈을 modules.v에 만들어 놓음

이제 젤 중요한 control module 구현이랑, 그거 관련해서 assign 해놓는 것들 구현 하고 => control 구현할때   //---------- Wire of ControlUnit ---------- 여기 이미 선언된 놈들 잘 확인 필요할듯

소스랑 다르게 하는? 작업 하고 돌려보면 될듯

Control 모듈은 modules.v에 넣으면 되지 않을까

아 그리고 내가 만든게
PC, ALU, ALUcontrol, ImmGen이고 완성되어서 주어진거가 memory, RegisterFile인데 얘들 다 input 들어가는 애들은 선언도 하고 처리는 되어 있는데 output에서 나와서 다른 데 들어갈 떄 필요한 combinational logic은 하나도 안 되어있음 => 참고

추가) ALU control unit 다시 검토 필요