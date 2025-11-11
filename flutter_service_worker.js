'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {".git/COMMIT_EDITMSG": "179c441547f6045ea1f3ae2c31a61a88",
".git/config": "cf1a8411212cbcc085c701d596a4f938",
".git/description": "a0a7c3fff21f2aea3cfa1d0316dd816c",
".git/FETCH_HEAD": "678bfca0f010f789e0d0b7871c69c6f0",
".git/HEAD": "cf7dd3ce51958c5f13fece957cc417fb",
".git/hooks/applypatch-msg.sample": "ce562e08d8098926a3862fc6e7905199",
".git/hooks/commit-msg.sample": "579a3c1e12a1e74a98169175fb913012",
".git/hooks/fsmonitor-watchman.sample": "a0b2633a2c8e97501610bd3f73da66fc",
".git/hooks/post-update.sample": "2b7ea5cee3c49ff53d41e00785eb974c",
".git/hooks/pre-applypatch.sample": "054f9ffb8bfe04a599751cc757226dda",
".git/hooks/pre-commit.sample": "5029bfab85b1c39281aa9697379ea444",
".git/hooks/pre-merge-commit.sample": "39cb268e2a85d436b9eb6f47614c3cbc",
".git/hooks/pre-push.sample": "2c642152299a94e05ea26eae11993b13",
".git/hooks/pre-rebase.sample": "56e45f2bcbc8226d2b4200f7c46371bf",
".git/hooks/pre-receive.sample": "2ad18ec82c20af7b5926ed9cea6aeedd",
".git/hooks/prepare-commit-msg.sample": "2b5c047bdb474555e1787db32b2d2fc5",
".git/hooks/push-to-checkout.sample": "c7ab00c7784efeadad3ae9b228d4b4db",
".git/hooks/sendemail-validate.sample": "4d67df3a8d5c98cb8565c07e42be0b04",
".git/hooks/update.sample": "647ae13c682f7827c22f5fc08a03674e",
".git/index": "41d13c1468e22bd55fe331ddde1c8e08",
".git/info/exclude": "036208b4a1ab4a235d75c181e685e5a3",
".git/logs/HEAD": "2e2fecf8adc32694c93b2c3cfc547d55",
".git/logs/refs/heads/main": "2e2fecf8adc32694c93b2c3cfc547d55",
".git/logs/refs/remotes/origin/HEAD": "19c05b5b37a769613b7b3d762fe9bad2",
".git/logs/refs/remotes/origin/main": "b7871606e467a03b165460f1dda4103d",
".git/objects/02/1d4f3579879a4ac147edbbd8ac2d91e2bc7323": "9e9721befbee4797263ad5370cd904ff",
".git/objects/05/8ff16942ab891640bf24bdc10d3bdfcc52d4c6": "008422d885853dedc923397d45108d7c",
".git/objects/0b/04728aa9cf59f743d139c493888ceab1b4729e": "10e6e71d3dd671cba76edc584ca82d29",
".git/objects/0e/50bcb660e4c6cef1a9464937e8a0e9f58b244e": "c8d376812656446418a69fad2284c3ca",
".git/objects/0f/3e36f474a1fd49b740f3d2745826fdb53d3a98": "9dcc8d84a8a3fbce207f3452a9db75bb",
".git/objects/14/7fe693ab667d8aa596ebf9fac1dfe6575c9f53": "bba1cd9334a636635a0037b32e95807e",
".git/objects/15/02f7fd4ac669055595aba543c5454011290a4b": "d2c9c336154fc01ad8b4b4d13febf30a",
".git/objects/18/9282defd0248d3376d1f93ae24c86360bc088b": "cd92fe272c386818eca07ed99874ee75",
".git/objects/19/a1ca0ba68587f77ef4d3d1ccf46b8291d8f039": "893eba9cbc239e5d2cb76597cd653b29",
".git/objects/1a/61705d2c1ba4fe1145d7737d830a9f4c88318e": "fdd37c0d250f3f08e940a8e1fd0af008",
".git/objects/1a/c259e99f19b6b2d120aead5b3851a02081a984": "d9856c17f67c59ce4ed778c906265979",
".git/objects/1e/7e5702feade2c2ff0e6957c3c2b5ad60bc4e9c": "95d7c7a9ef0d30b778bcce46429dee93",
".git/objects/1e/aa34a24a7952cea580fc132b25ca0258769d72": "1fd741e1e0c87cb45129efbf78d13842",
".git/objects/1f/b8b7aedba879441ffb37a865af806197a64781": "181c34d00c335cb601ac1672a80fe07e",
".git/objects/1f/e286799ce664e2e87c6e4f7497517232b1eecb": "56a230a1b518674e315a87b12747f28f",
".git/objects/20/3a3ff5cc524ede7e585dff54454bd63a1b0f36": "4b23a88a964550066839c18c1b5c461e",
".git/objects/22/187e3f9b4890c7e27f6f9d8aa7920d7c3b5492": "101d424ecb4e5c3b1c7ec4fa8606a8f5",
".git/objects/25/edb0fba4e5b2e0a0400df524f3045cf2ddd16a": "3c3b685e1462cd3a6e1540efcd092429",
".git/objects/29/f22f56f0c9903bf90b2a78ef505b36d89a9725": "e85914d97d264694217ae7558d414e81",
".git/objects/2b/fdb08c6929c7110959f010091d052464703728": "743421d5e9f3cd0db26017172ecff933",
".git/objects/2c/03288764f1d32d32ee66a239c688398fd18657": "b8c14f1275d4df50a2097f0641cf1d1c",
".git/objects/2c/bf9b4eb707fdf9f2f3b959a9cc17e61405aead": "7eb097fd75e1e3af647a6f8fa539e502",
".git/objects/2e/e8ee9b5c2fe229404907cea642ad334828909e": "3633df200f98607e35c35d8aee727369",
".git/objects/31/18761291613f971dd3f171a43c5de1002a3298": "e0dbdf08b8d1de6d68a1332f8f9a289a",
".git/objects/31/db5ab4576deca70a7e5b9844f4264c372300ba": "69bbe6fb329d2e720a874e5d512d804a",
".git/objects/32/bc52c0f7ff40bb3cd0055da2fd4e030f8fe7bb": "ba32e5de6a90b1294f06366aafe76de9",
".git/objects/3b/478ba6d96f8a7a72a0915db17b7951717423a8": "933af8e39818df917074ba193e914ccc",
".git/objects/3c/479d35c7d87c997841918c01968aca6366f4bf": "3f90c903de8ac27871a35b3a5866586a",
".git/objects/43/8cdee2856f91723ae2796d89f5102b83428769": "ed368763706b147df09b7e90746a5d32",
".git/objects/46/4ab5882a2234c39b1a4dbad5feba0954478155": "2e52a767dc04391de7b4d0beb32e7fc4",
".git/objects/49/5bebe3fc11221c89b7ba87598f6a0c9335f2fe": "f7a5637be8bf102109dd9f51c5fbac7c",
".git/objects/4a/243579732686c32ffa40cff80b797d8ae7cfb2": "0c29b08ca50ef2df4aa2325fc806f444",
".git/objects/4a/91571f48a82e900705498153f8a5dd2327cff7": "df6f851ed8faa500f15b7973e115750a",
".git/objects/4b/3427c7d7b2cf598daf208010eb70838d3fa9f3": "7f6a15e38203320e4d3de03027fff07b",
".git/objects/4d/bf9da7bcce5387354fe394985b98ebae39df43": "534c022f4a0845274cbd61ff6c9c9c33",
".git/objects/4f/fbe6ec4693664cb4ff395edf3d949bd4607391": "2beb9ca6c799e0ff64e0ad79f9e55e69",
".git/objects/50/63c297873258e67cbb8ff6b14f6307134c360d": "3a00455c025d1d308faa3ba839baff19",
".git/objects/53/3fbf6f8e8ab31f412fa1078c6d2f14f20867df": "e057290adb31018eaa7761a0bb9c073a",
".git/objects/56/b1baf8216a5773a2638ec4e1833aa9c11f7720": "a54fe416a4087f101f9a8609b595ac8c",
".git/objects/57/c11e2aab3fdabdd27579d81572176d0d487817": "935430eaa051ee794245fbf1932770f3",
".git/objects/5a/f80fbf8e15144eb4e9026554c3867b8dda1c2d": "c84d3b550981a40e73f8d6816611dbe3",
".git/objects/5f/cf02b76db3b621ce80feb1b54d563ef66aa88d": "51f6a4fc33363cecca3beac7e05e5ee3",
".git/objects/63/98febacc3361dadeb23a1196f329bc0d7aa211": "95b99bbe0efd75798f8aab29ed6165c0",
".git/objects/68/aa566846e0c99d03731c20b7d6124aa9421eaf": "4bd036efd5bdd252e42e1e61a809b9d0",
".git/objects/6b/9862a1351012dc0f337c9ee5067ed3dbfbb439": "85896cd5fba127825eb58df13dfac82b",
".git/objects/70/c8e41a7c798b44bfb66bdb9d8b9c4f86827c92": "8cc22d71197732d0a40d4c09409fd0c7",
".git/objects/71/233a71300aa3d3fcf744d901e5f10120f33489": "ea92ea6f8577e76e00b914b23cf442fa",
".git/objects/73/4a9ea791ceaefa8e2903085029103e5d1309ac": "d81b57be5e02c9495a8d656603d2fe68",
".git/objects/74/64e457b0dc9954a8186a94f2c2216fc185ee16": "02fe8362aa6aa10fde3582df1f2d0274",
".git/objects/74/e0e4bbd1dd75467b26b7cc8607dd7fe0de6466": "e3c0df88997b5804907559ec861f5db3",
".git/objects/75/ac9453391f480cd8a30b166ca8f33eb1a3b242": "fba6f9781ef28fb06863e5c37cc0b8d4",
".git/objects/76/634210e024d2dfacae728989c6924b0358e46c": "d0c99a63f97e68af02b06deeacbc7fc4",
".git/objects/76/d4087c6ee9a8b27351127e3a518112cc578151": "5edcc7dbc8904cc87fd9a96b6a4bd628",
".git/objects/79/b135bcfa1b73758f9065ffdd2da02a71f3fd36": "9fa12141218651c357d2bbfe8f5750ed",
".git/objects/7a/6c1911dddaea52e2dbffc15e45e428ec9a9915": "f1dee6885dc6f71f357a8e825bda0286",
".git/objects/7a/6ed81a0eae77f0da1e5857208285fcf0f78942": "2ea198b0f59c1bd592a8418dad3909f1",
".git/objects/7d/a416e04bb61815950fe1bc6cfe0294a1b61e82": "2ae36704bf38c7645eebf25c73668a7b",
".git/objects/7f/76a63628a7274f4db83c9cf08efa42a4f10fe3": "f483c72e80a3954adb4ce9df70075a62",
".git/objects/80/53a098be5e88822f564656950f32903d8af294": "3884b71e1e2e9b7a5c6ad458079794a4",
".git/objects/81/fd2ce861c74ba1548ed41f557e18b4b344631d": "ec7019a6521861bf6a8991c6dbbf154a",
".git/objects/88/3b9f067f95a7987d699921f5d02cc7879bbe60": "6bb0ed4ca87a062720941235626f608c",
".git/objects/88/cfd48dff1169879ba46840804b412fe02fefd6": "e42aaae6a4cbfbc9f6326f1fa9e3380c",
".git/objects/8a/aa46ac1ae21512746f852a42ba87e4165dfdd1": "1d8820d345e38b30de033aa4b5a23e7b",
".git/objects/8a/c9b67d98eee61d3859024a5b5767a886582fb7": "5b2a1491f4f6d93cef7df5ebee08b070",
".git/objects/8c/3037402476fe1bf8a36e1df2094edf436e0fac": "5eccdf8568cde9adb43754907daf3ec7",
".git/objects/8e/77fa07cc871f97f81c9ebedbfbebb0b0c45c2b": "6bb8e3f92fe5ab9c33ba93619d020274",
".git/objects/90/ec732821ee792ced721b4b69db31f26371920f": "9fc2ae3ccdf8058a6d9fefcd9bdfb3ff",
".git/objects/96/7bc783d2623c12ec5571ec98190d677e9c7325": "5bfbeb8c7702b146fe5a373a5917274d",
".git/objects/98/0a843e553a1ccefd9e35faed3eac3aec935f8e": "fe2f020c98ae53321267584b83add949",
".git/objects/98/0d49437042d93ffa850a60d02cef584a35a85c": "8e18e4c1b6c83800103ff097cc222444",
".git/objects/9a/b8d54fcc65639b96445a42d9c8173e02a64de0": "3c754aa60833009a34167de65024b629",
".git/objects/9b/3ef5f169177a64f91eafe11e52b58c60db3df2": "91d370e4f73d42e0a622f3e44af9e7b1",
".git/objects/9d/d19fcfb5f1c75c7228db8da36fe1b62dda23c5": "c21bbc2767d2121e212533a846435d28",
".git/objects/9e/3b4630b3b8461ff43c272714e00bb47942263e": "accf36d08c0545fa02199021e5902d52",
".git/objects/a1/5e39e9cd2d2dbcc58edef02a1e8b32db5b53d2": "332f939d26992819403e950b6f8a0606",
".git/objects/a5/7e8d586650c033348e15f1b0e88b14201d8a94": "6f047dd5379fd4ca6360ee54c35136bf",
".git/objects/a5/c12399a28aafa284880629c38ca8b784b919cd": "a026952bb1cde37c6b64f0089a8084b7",
".git/objects/a6/7bc93a69ae7474cc12c87493b3797380bf7bd1": "815633f74df838fd8e388369ec91bde8",
".git/objects/aa/497e65997c84df5baaaf5edbce85e2827b234b": "b33699c13a51c5a0accec7422b926118",
".git/objects/aa/a498c3ff2895b78e021036dc7a5e8b1e82bb7c": "d364914179bc930b6b37a42a591aa96b",
".git/objects/ab/4bddf01b1ad8042bd1d30bd450bda4aca22f9b": "3761efd8d6994784ca2ab351c4f18425",
".git/objects/ad/6f35bcebaf4e9c6beac210e8013d1f75d970f0": "c7826de4d3d42adf3968251e95cba2d4",
".git/objects/ae/857a9492c530b50bc52f8e5043ab12157953d6": "678a4b2243387f1370c6050e3b96ae2c",
".git/objects/b0/70dad52506177c45a797b6f04edcc9a3c5e63c": "0be5489715914be5a09fb90c8ec39abb",
".git/objects/b2/1d4c01dfe3778af044dc4b2dbbac8060319fd0": "0f800579b92515354bdd3fedcf87ab18",
".git/objects/b2/46f80da0f241851a770f37e3874440d278ffba": "0eb60a58b0ca27d2475d51f15939c557",
".git/objects/b3/a92a44cf41de2a8af4fe478bf8ae5def4a8e5a": "7ab6edcf40d6633adb1bfd897d7b2fd9",
".git/objects/b6/b8806f5f9d33389d53c2868e6ea1aca7445229": "b14016efdbcda10804235f3a45562bbf",
".git/objects/b7/49bfef07473333cf1dd31e9eed89862a5d52aa": "36b4020dca303986cad10924774fb5dc",
".git/objects/b8/9e1141048aacd74b1fc9817b7333f7fa38a21f": "d987a9529b064c09e135b0f0dfb01b9a",
".git/objects/b9/2a0d854da9a8f73216c4a0ef07a0f0a44e4373": "f62d1eb7f51165e2a6d2ef1921f976f3",
".git/objects/b9/36d0311d57bb9250d7d947a2f27884b141301b": "98f6635ad5968b5e262a084043e652f9",
".git/objects/b9/7ce53e83da6e6f58efc6f9d29dff5967a0db0c": "623d3be504ead75e97397a8b29753891",
".git/objects/bd/269b03b7e5f0dbdeb54cd87a7941274bef8dad": "fcbcc7a616dcfdbcb7d38f3a04f3eb91",
".git/objects/bf/eb14cb660da7de3667dfc519983f98c9d8bd5d": "f339caaf4ca0fca619691c077c94b115",
".git/objects/c3/dd3e941b3beb1492da35f80958400eccf90a67": "385be0b6808d1856e11e5c45ea5071bc",
".git/objects/c4/016f7d68c0d70816a0c784867168ffa8f419e1": "fdf8b8a8484741e7a3a558ed9d22f21d",
".git/objects/c4/1026fc2fb82ed46b6f9ddf14a5dd299a242317": "6452a6f9ce3c24df9ef649a8691bdc84",
".git/objects/c6/17e3f9bde17e81db903ef340f39c948ac58fd4": "4c55db96a7132c954e4ba4f2bec9cb35",
".git/objects/c6/24e3d2b0513cc13d45a170bd128b02b29f9ac0": "bbaac61d8078a37c0a6c7123aeaddc47",
".git/objects/c8/623e3077ae3d6369e82ed501cc1078ca7e6644": "a39de70fdceb2103d155065fb2c4ec96",
".git/objects/ca/3bba02c77c467ef18cffe2d4c857e003ad6d5d": "316e3d817e75cf7b1fd9b0226c088a43",
".git/objects/cd/84601432ffd3c1d62706030feb5ae06e88903e": "3bc25c06c7795884af1a5d94734cf266",
".git/objects/d0/b43f2fa0b679d84f3c50f9c6b01c20d9b95887": "350bba15c741c86e0ccb5d724b55ec3e",
".git/objects/d0/d0ca4cf4d29fb81a61a86f017349e13d7743b4": "631c7458a8c79b7ac7eccbb916847e2c",
".git/objects/d4/3532a2348cc9c26053ddb5802f0e5d4b8abc05": "3dad9b209346b1723bb2cc68e7e42a44",
".git/objects/d4/592b347f1f7c38fd7f69aef5880cc355fd705c": "cf7e9d2d71638b7d05788b07fe0a65aa",
".git/objects/d4/a39ecd7ea07efe1842601efc49885ec2bf86d3": "9879859149580deb34c7540dc19c272d",
".git/objects/d6/68328a6246aaaa46ac1a8acc421ac47895fa0d": "8d4371e56d7f94c6da7e0f4fc3ecceda",
".git/objects/d6/9c56691fbdb0b7efa65097c7cc1edac12a6d3e": "868ce37a3a78b0606713733248a2f579",
".git/objects/d7/ac7c7e06c174ff9c4010836c2d6978ce852b23": "fe453fd6536dc9ae9c105ad757af4b33",
".git/objects/d7/c3ab774541455e2826fd4904e5f329cbe3930c": "706fb3a2e8ecd86e55b857240457c3c6",
".git/objects/d9/229a2f022784f93f683a85212bd568bca072a4": "8d2871a27e57fdb19af2de82890c18a4",
".git/objects/db/c989d6f29445415650e34f466551aff2a01fe8": "1f3bae8a43cd5e0cae2086dfd504df81",
".git/objects/de/d2bc642adf4de9130ec1175baf7ce5cab768ef": "44bee6a008060f52aba245d0f9366f89",
".git/objects/df/48a1c156be2238b926c7ed52667819bd6b410b": "c7e3a11b99728dc670700f6b738b3410",
".git/objects/df/e0770424b2a19faf507a501ebfc23be8f54e7b": "76f8baefc49c326b504db7bf751c967d",
".git/objects/e0/87ac6a2c971545dc3bb435951650e1b35c3e61": "c3091f64f2ba6381bad3358e5f93af57",
".git/objects/e1/9a9803f1972f8f84bb9dd0c8bf30fd2b9153d9": "ed740a0dcf3298715ad302cb2f6ab3e0",
".git/objects/e2/c7bc2a3b6095982b59ef128407e1d286477d29": "315e1e2078f0938f447e95e4ebb29cf7",
".git/objects/e3/7a13b1b949619a4d1924fdd2ba198d07a69513": "e516dbe74fcd36b2646a972aee4544a7",
".git/objects/e3/e9ee754c75ae07cc3d19f9b8c1e656cc4946a1": "14066365125dcce5aec8eb1454f0d127",
".git/objects/e4/67285c895b54204ffe73be08ff229e5f4cd12f": "521f08dd603a590ca326c0b95334d2a3",
".git/objects/e5/812688f48d1264e30ba5875fe5f0450e678c80": "f52b2e3ee6e81129ea4b37881b492bda",
".git/objects/e9/94225c71c957162e2dcc06abe8295e482f93a2": "2eed33506ed70a5848a0b06f5b754f2c",
".git/objects/eb/9b4d76e525556d5d89141648c724331630325d": "37c0954235cbe27c4d93e74fe9a578ef",
".git/objects/ed/b55d4deb8363b6afa65df71d1f9fd8c7787f22": "886ebb77561ff26a755e09883903891d",
".git/objects/ef/192508a1304f5a05a56b7becfda66c54f980f4": "a8486f12d0a00da146cde72b4dd72cef",
".git/objects/f1/591be6274d974b5c5be8ac815458e58d738388": "19ddca7b34c4559643ebaad1f917cce7",
".git/objects/f2/04823a42f2d890f945f70d88b8e2d921c6ae26": "6b47f314ffc35cf6a1ced3208ecc857d",
".git/objects/f3/8ce43c5198666a37236d981228e5435dc2fb65": "2fe4355f7c3dd3fabd62ea66185b2f9c",
".git/objects/f4/2a9bcecb966ad4518e8994d2325dc3d3e5b21b": "52bd5b56391c4022a14a9be6a4314b87",
".git/objects/f4/b2349f834865898907fce7e2f2236a5b4501b3": "1b80990329b4ed4d3afc799bb990f4eb",
".git/objects/f5/72b90ef57ee79b82dd846c6871359a7cb10404": "e68f5265f0bb82d792ff536dcb99d803",
".git/objects/f5/85e6a0446b2a23f4c3d3aa046f0c3bb4cd7af9": "770b62c89ab19176a8bba0d7358ae608",
".git/objects/fa/27469d3c9f52a48fa92d63c6c902614f980181": "af26d7b4242250d08700f02c32e3b611",
".git/objects/fe/3b987e61ed346808d9aa023ce3073530ad7426": "dc7db10bf25046b27091222383ede515",
".git/refs/heads/main": "d8d19e0b5da5716cf8cd75c9d2b53b0c",
".git/refs/remotes/origin/HEAD": "98b16e0b650190870f1b40bc8f4aec4e",
".git/refs/remotes/origin/main": "d8d19e0b5da5716cf8cd75c9d2b53b0c",
"assets/AssetManifest.bin": "ea883c608a7732d38e492e1d21a0f9c6",
"assets/AssetManifest.bin.json": "677d071e8c550082c12f20f8ed1b23e5",
"assets/AssetManifest.json": "6da6d6c71f726de317be04e8a3f26160",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/fonts/MaterialIcons-Regular.otf": "52a9d6452ffc7fb92c6a8fb8cdeea56a",
"assets/NOTICES": "87caa28754de940f49909d445b82d3e5",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/packages/pdfrx/assets/pdfium.wasm": "d4f7ac5f1cb87453b04726dff0a88941",
"assets/packages/pdfrx/assets/pdfium_client.js": "9ef7c314155dc36c966ef89df070dfd2",
"assets/packages/pdfrx/assets/pdfium_worker.js": "18a5a38438b4ce448c164399c8024fcd",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"canvaskit/canvaskit.js": "140ccb7d34d0a55065fbd422b843add6",
"canvaskit/canvaskit.js.symbols": "58832fbed59e00d2190aa295c4d70360",
"canvaskit/canvaskit.wasm": "07b9f5853202304d3b0749d9306573cc",
"canvaskit/chromium/canvaskit.js": "5e27aae346eee469027c80af0751d53d",
"canvaskit/chromium/canvaskit.js.symbols": "193deaca1a1424049326d4a91ad1d88d",
"canvaskit/chromium/canvaskit.wasm": "24c77e750a7fa6d474198905249ff506",
"canvaskit/skwasm.js": "1ef3ea3a0fec4569e5d531da25f34095",
"canvaskit/skwasm.js.symbols": "0088242d10d7e7d6d2649d1fe1bda7c1",
"canvaskit/skwasm.wasm": "264db41426307cfc7fa44b95a7772109",
"canvaskit/skwasm_heavy.js": "413f5b2b2d9345f37de148e2544f584f",
"canvaskit/skwasm_heavy.js.symbols": "3c01ec03b5de6d62c34e17014d1decd3",
"canvaskit/skwasm_heavy.wasm": "8034ad26ba2485dab2fd49bdd786837b",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"flutter.js": "888483df48293866f9f41d3d9274a779",
"flutter_bootstrap.js": "4688983c2632a2b92715a51ba343d627",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"index.html": "79af8377415649d8a9617c0048b81710",
"/": "79af8377415649d8a9617c0048b81710",
"LICENSE": "84e3500713f5a69a2b22b6344061cbe3",
"main.dart.js": "985112d51412e0b9bc8aba2442001179",
"manifest.json": "f00df2e5386294ca4c24a4d2015c1b0b",
"version.json": "809771a9c3cd09460a3494661ca25526"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
