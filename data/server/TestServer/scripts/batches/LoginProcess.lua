require("cryptic/Batch");
require("cryptic/Var");

Var.Default(nil, "LoginProcess_LoginExisting", 10000);
Var.Default(nil, "LoginProcess_LoginsPerSec", 30);
Var.Default(nil, "LoginProcess_CreateCharacters", 10000);
Var.Default(nil, "LoginProcess_CreatesPerSec", 30);

Batch.Begin();
Batch.TestMustSucceed("LoginProcess/CreateCharacters");
Batch.TestMustSucceed("LoginProcess/UseExisting");
Batch.End();