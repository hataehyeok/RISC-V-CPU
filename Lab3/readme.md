일단은 원래 주어진거 top.v랑 cpu.v랑 Memory.v랑 RegisterFile.v임
그중에 Memory랑 RegisterFile은 완성본 주어짐

그래가지고 sangy00n 소스랑 예전에 싱사시 한거 보면서
PC 모듈을 PC.v에, ALU 모듈을 alu.v에, Immgeneratro 모듈을 modules.v에 만들어 놓음

이제 젤 중요한 control module 구현이랑, 그거 관련해서 assign 해놓는 것들 구현 하고
소스랑 다르게 하는? 작업 하고 돌려보면 될듯

Control 모듈은 modules.v에 넣으면 되지 않을까

