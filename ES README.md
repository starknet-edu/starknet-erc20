# ERC20 on StarkNet

¡Bienvenidos! Este es un taller automatizado que explicará cómo implementar un token ERC20 en StarkNet y personalizarlo para realizar funciones específicas. El estándar ERC20 se describe [aquí](https://docs.openzeppelin.com/contracts/3.x/api/token/erc20). Está dirigido a desarrolladores que: 

- Comprender la sintaxis de Cairo 
- Comprender el estándar de token ERC20.

Este tutorial ha sido escrito por Florian Charlier ([@trevis_dev](https://twitter.com/trevis_dev)) en colaboración de Henri Lieutaud and Lucas Levy, basado en los originales de Henri[ERC20 101](https://github.com/l-henri/erc20-101) y [ERC20 102](https://github.com/l-henri/erc20-102) tutoriales de Solidity.

Repo original [Aquí](https://github.com/starknet-edu/starknet-erc20).

## Introducción

### Disclaimer

No espere ningún tipo de beneficio al usar esto, aparte de aprender un montón de cosas interesantes sobre StarkNet, el primer paquete acumulativo de validez de propósito general en Ethereum Mainnet. 

StarkNet todavía está en Alfa. Esto significa que el desarrollo está en curso y que la pintura no está seca en todas partes. Las cosas mejorarán y, mientras tanto, ¡hacemos que las cosas funcionen con un poco de cinta adhesiva aquí y allá! 

### ¿Cómo funciona?

El objetivo de este tutorial es personalizar e implementar un contrato ERC20 en StarkNet. Su progreso será verificado por un [contrato de evaluador](contratos/Evaluador.cairo), implementado en StarkNet, que le otorgará puntos en forma de [tokens ERC20](contratos/token/ERC20/TUTOERC20.cairo). 

Cada ejercicio requerirá que agregue funcionalidad a su token ERC20. 

Para cada ejercicio, deberá escribir una nueva versión en su contrato, implementarlo y enviarlo al evaluador para su corrección.

### ¿Dónde estoy? 

Este taller es el segundo de una serie destinada a enseñar cómo construir en StarkNet. Echa un vistazo a lo siguiente:
​

| Tema                                           | GitHub repo                                                                            |
| ---------------------------------------------- | -------------------------------------------------------------------------------------- |
| Aprenda a leer el código de El Cairo           | [Cairo 101](https://github.com/starknet-edu/starknet-cairo-101)                        |
| Implemente y personalice un ERC721 NFT         | [StarkNet ERC721](https://github.com/starknet-edu/starknet-erc721)                     |
| Implemente y personalice un token ERC20 (aquí) | [StarkNet ERC20](https://github.com/starknet-edu/starknet-erc20)                       |
| Cree una app de capa cruzada                   | [StarkNet messaging bridge](https://github.com/starknet-edu/starknet-messaging-bridge) |
| Depure sus contratos de El Cairo fácilmente    | [StarkNet debug](https://github.com/starknet-edu/starknet-debug)                       |
| Diseña tu propio contrato de cuenta            | [StarkNet account abstraction](https://github.com/starknet-edu/starknet-accounts)      |

### Proporcionar comentarios y obtener ayuda 

Una vez que haya terminado de trabajar en este tutorial, ¡sus comentarios serán muy apreciados!

Complete [este formulario](https://forms.reform.app/starkware/untitled-form-4/kaes2e) para informarnos qué podemos hacer para mejorarlo. 

Y si tiene dificultades para seguir adelante, ¡háganoslo saber! Este taller está destinado a ser lo más accesible posible; queremos saber si no es el caso. 

¿Tienes alguna pregunta? Únase a nuestro servidor [Discord server](https://starknet.io/discord), regístrese y únase al canal #tutorials-support. ¿Está interesado en seguir talleres en línea sobre cómo aprender a desarrollar en StarkNet? [Subscríbete aquí](http://eepurl.com/hFnpQ5)

### Contribuyendo 

Este proyecto se puede mejorar y evolucionará a medida que StarkNet madure. ¡Sus contribuciones son bienvenidas! Aquí hay cosas que puede hacer para ayudar: 

- Crea una sucursal con una traducción a tu idioma .
- Corrija los errores si encuentra algunos. 
- Agregue una explicación en los comentarios del ejercicio si cree que necesita más explicación.
- Agregue ejercicios que muestren su característica favorita de El Cairo​.


## Preparándose para trabajar 

### Paso 1: Clonar el repositorio 

- Oficial:

```bash
git clone https://github.com/starknet-edu/starknet-erc20
cd starknet-erc721
```

### Paso 2: Configure su entorno 

Hay dos formas de configurar su entorno en StarkNet: Una instalación local o usando un contenedor docker.

- Para usuarios de Mac y Linux, recomendamos either
- Para usuarios de Windows recomendamos docker 

Para obtener instrucciones de configuración de producción, escribimos [este artículo](https://medium.com/starknet-edu/the-ultimate-starknet-dev-environment-716724aef4a7).

#### Opción A: Configurar un entorno Python local 

Configure el entorno siguiendo [estas instrucciones](https://starknet.io/docs/quickstart.html#quickstart)
- Instalar [OpenZeppelin's cairo contracts](https://github.com/OpenZeppelin/cairo-contracts).

```bash
pip install openzeppelin-cairo-contracts
```

#### Opción B: Usar un entorno dockerizado

- Linux y macos

Para mac m1: 

```bash
alias cairo='docker run --rm -v "$PWD":"$PWD" -w "$PWD" shardlabs/cairo-cli:latest-arm'
```

Para amd procesadores

```bash
alias cairo='docker run --rm -v "$PWD":"$PWD" -w "$PWD" shardlabs/cairo-cli:latest'
```

- Windows

```bash
docker run --rm -it -v ${pwd}:/work --workdir /work shardlabs/cairo-cli:latest
```

#### Paso 3: Pruebe que puede compilar el proyecto contratos de compilación

```bash
starknet-compile contracts/Evaluator.cairo
```

## Trabajando en el tutorial 

### Flujo de trabajo 

Para hacer este tutorial tendrás que interactuar con el contrato [`Evaluator.cairo`](contracts/Evaluator.cairo). Para validar un ejercicio tendrás que:

- Leer el código del evaluador para averiguar qué se espera de su contrato 
- Personaliza el código de tu contrato 
- Despliéguelo en la red de prueba de StarkNet. Esto se hace usando la CLI. 
- Registre su ejercicio para corrección, usando la función de `submit_exercise` en el evaluador. Esto se hace usando Voyager. 
- Llame a la función correspondiente en el contrato del evaluador para corregir su ejercicio y recibir sus puntos. Esto se hace usando Voyager. 

Por ejemplo para resolver el primer ejercicio el flujo de trabajo sería el siguiente: 


`deploy a smart contract that answers ex1` &rarr; `call submit_exercise on the evaluator providing your smart contract address` &rarr; `call ex2_test_erc20 on the evaluator contract`

**Su objetivo es reunir tantos puntos ERC20-101 como sea posible.** Tenga en cuenta : 

- La función de 'transferencia' de ERC20-101 ha sido deshabilitada para alentarlo a terminar el tutorial con una sola dirección Para recibir puntos, el evaluador debe alcanzar las llamadas a la función distribuir_punto. 
- Este repositorio contiene dos interfaces ([`IERC20Solution.cairo`](contracts/IERC20Solution.cairo) y [`IExerciseSolution.cairo`](contracts/IERC20Solution.cairo)). Por ejemplo, para la primera parte, su contrato ERC20 deberá ajustarse a la primera interfaz para validar los ejercicios; es decir, su contrato debe implementar todas las funciones descritas en `IERC20Solution.cairo`. 

- **Realmente recomendamos que lea el contrato de [`Evaluator.cairo`](contracts/Evaluator.cairo) para comprender completamente lo que se espera de cada ejercicio**. En este archivo Léame se proporciona una descripción de alto nivel de lo que se espera de cada ejercicio. 

- El contrato de Evaluador a veces necesita realizar pagos para comprar sus tokens. ¡Asegúrate de que tenga suficientes fichas ficticias para hacerlo! De lo contrario, debe obtener tokens ficticios del contrato de tokens ficticios y enviarlos al evaluador.


### Direcciones y contratos oficiales

| Contract code                                                     | Contract on voyager                                                                                                                                                           |
| ----------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [Points counter ERC20](contracts/token/ERC20/TUTOERC20.cairo)     | [0x228c0e6db14052a66901df14a9e8493c0711fa571860d9c62b6952997aae58b](https://goerli.voyager.online/contract/0x228c0e6db14052a66901df14a9e8493c0711fa571860d9c62b6952997aae58b) |
| [Evaluator](contracts/Evaluator.cairo)                            | [0x14ece8a1dcdcc5a56f01a987046f2bd8ddfb56bc358da050864ae6da5f71394](https://goerli.voyager.online/contract/0x14ece8a1dcdcc5a56f01a987046f2bd8ddfb56bc358da050864ae6da5f71394) |
| [Dummy ERC20 token (DTK20)](contracts/token/ERC20/DTKERC20.cairo) | [0x66aa72ce2916bbfc654fd18f9c9aaed29a4a678274639a010468a948a5e2a96](https://goerli.voyager.online/contract/0x66aa72ce2916bbfc654fd18f9c9aaed29a4a678274639a010468a948a5e2a96) |

​
​
## Lista de tareas 

¡Hoy implementará su propio token ERC20 en StarkNet! 

El tutorial está estructurado en dos partes

- En la primera parte (ejercicios 1 a 9), deberá implementar un contrato ERC-20. 
- En la segunda parte (ejercicios 10 a 18), implementará otro contrato que tendrá que interactuar con tokens ERC20.

### Ejercicio 1: Implementación de un ERC20 

- Llame a [`ex1_assign_rank()`](contracts/Evaluator.cairo#L134) en el contrato del evaluador para recibir un ticker aleatorio para su token ERC20, así como un suministro de token inicial (1 pt). Puede leer su ticker asignado y suministrarlo a través de la [página del evaluador en Voyager](https://goerli.voyager.online/contract/0x14ece8a1dcdcc5a56f01a987046f2bd8ddfb56bc358da050864ae6da5f71394) llamando a los captadores [`read_ticker()`]((contracts/Evaluator.cairo#L93 )) y [`read_supply()`](contracts/Evaluator.cairo#L102).
- Cree un contrato de token ERC20 con el ticker y el suministro adecuados. Puede usar [esta implementación](https://github.com/OpenZeppelin/cairo-contracts/blob/main/src/openzeppelin/token/erc20/ERC20.cairo) como base (2 pts) 
- Implementarlo en el testnet (verifique el constructor para los argumentos necesarios. También tenga en cuenta que los argumentos deben ser decimales). (1 punto)



```bash
starknet-compile contracts/token/ERC20/ERC20.cairo --output artifacts/ERC20.json
starknet deploy --contract ERC20 --inputs arg1 arg2 arg3 --network alpha-goerli 
```

- Llame a [`submit_erc20_solution()`](contracts/Evaluator.cairo#L733) en el Evaluador para establecer el contrato que desea evaluar (2 puntos) (los 3 puntos anteriores para el ERC20 y la implementación también se atribuyen en ese paso).


### Ejercicio 2: Verificación de su ERC20

- Llame a [`ex2_test_erc20()`](contracts/Evaluator.cairo#L150) en el evaluador para que verifique el ticker y suministre y atribuya sus puntos (2 puntos)


### Ejercicio 3 - Creación de un Faucet

- Cree una función `get_tokens()` en su contrato. Debería acuñar parte de su token para la persona que llama. Deberá devolver el monto exacto que acuña para que el Evaluador verifique que el incremento de saldo y el monto enviado correspondan.
- Implemente su contrato y llame a [`submit_erc20_solution()`](contracts/Evaluator.cairo#L733) en el Evaluador para registrarlo
- Llame a la función [`ex3_test_get_token()`](contracts/Evaluator.cairo#L209) que distribuye tokens a la persona que llama (2 pts).


### Ejercicios 4, 5 y 6 - Creación de una lista de permitidos

- Crear una función de lista de permisos de clientes. Solo permitir que los usuarios de la lista puedan llamar a `get_tokens()`.
- Crear una función `request_allowlist()` que el evaluador llamará durante la comprobación del ejercicio para poder obtener tokens.
- Cree una función `allowlist_level()` a la que cualquiera pueda llamar para saber si una cuenta puede obtener tokens.
- Implemente su contrato y llame a [`submit_erc20_solution()`](contracts/Evaluator.cairo#L733) en el Evaluador para registrarlo
- Llame a [`ex4_5_6_test_fencing()`](contracts/Evaluator.cairo#L231) en el evaluador para mostrar
   - No puede obtener tokens usando `get_tokens()` (1 pt)
   - Puede llamar a `request_allowlist()` y tener confirmación de que pasó (1 pt)
   - Luego puede obtener tokens usando el mismo `get_tokens()` (2 pt)


### Ejercicios 7, 8 y 9: creación de una lista de permitidos de varios niveles

- Crear una función de listado de múltiples niveles de clientes. Solo permitir que los usuarios de la lista puedan llamar a `get_token()`; y los clientes deben recibir una cantidad diferente de tokens según su nivel
- Cree una función `request_allowlist_level()` que el evaluador llamará durante la verificación del ejercicio para poder obtener tokens en un cierto nivel de nivel
- Modificar la función `allowlist_level()` para que devuelva el nivel permitido de cuentas.
- Implemente su contrato y llame a [`submit_erc20_solution()`](contracts/Evaluator.cairo#L733) en el Evaluador para registrarlo
- Llame a [`ex7_8_9_test_fencing_levels()`](contracts/Evaluator.cairo#L291) en el evaluador para mostrar
   - No puede obtener tokens usando `get_tokens()` (1 pt)
   - Puede llamar a `request_allowlist_level(1)` , luego llamar a `get_tokens()` y obtener N tokens (2 puntos)
   - Puede llamar a `request_allowlist_level(2)` , luego llamar a `get_tokens()` y obtener > N tokens (2 puntos)
   

### Ejercicio 10 - Reclamación de dummy tokens

- Reclamar tokens manualmente en el reclamable preimplementado [ERC20](https://goerli.voyager.online/contract/0x66aa72ce2916bbfc654fd18f9c9aaed29a4a678274639a010468a948a5e2a96) ([DTK tokens](contracts/token/ERC20/DTKERC20.cairo)) (1 pts)
- Reclama tus puntos llamando a [`ex10_claimed_tokens()`](contracts/Evaluator.cairo#L364) en el evaluador (1 pts)


### Ejercicio 11 - Llamar al faucet desde tu contrato

- Crear un contrato `ExerciseSolution` que:
   - Puede reclamar y mantener tokens DTK en nombre de la dirección que llama
   - Realiza un seguimiento de las direcciones que reclamaron tokens y cuánto
   - Implementa una función `tokens_in_custody` para mostrar estas cantidades reclamadas
- Implemente su contrato y llame a [`submit_exercise_solution()`](contracts/Evaluator.cairo#L754) en el Evaluador para registrarlo
- Llame a [`ex11_claimed_from_contract()`](contracts/Evaluator.cairo#L383) en el evaluador para probar que su código funciona (3 pts)


### Ejercicio 12: uso de transferFrom en un ERC20

- Cree una función `withdraw_all_tokens()` en `ExerciseSolution` para retirar los tokens reclamados de `ExerciseSolution` a la dirección que los reclamó inicialmente
- Implemente su contrato y llame a [`submit_exercise_solution()`](contracts/Evaluator.cairo#L754) en el Evaluador para registrarlo
- Llame a [`ex12_withdraw_from_contract()`](contracts/Evaluator.cairo#L431) en el evaluador para probar que su código funciona (2 pts)


### Ejercicio 13 - Aprobar

- Acuñe algunos tokens DTK y use voyager para autorizar al evaluador a manipularlos
- Llame a [`ex13_approved_exercise_solution()`](contracts/Evaluator.cairo#L491) para reclamar puntos (1 pts)


### Ejercicio 14 - Revocación de la aprobación

- Utilizar voyager para revocar la autorización anterior.
- Llame a [`ex14_revoked_exercise_solution()`](contracts/Evaluator.cairo#L512) para reclamar puntos (1 pts)


### Ejercicio 15 - Usando transferFrom

- Cree una función `deposit_tokens()` en su contrato a través de la cual un usuario pueda depositar DTK en `ExerciseSolution`, utilizando `transferFrom` de DTK
- Implemente su contrato y llame a [`submit_exercise_solution()`](contracts/Evaluator.cairo#L754) en el Evaluador para registrarlo
- Llame a [`ex15_deposit_tokens`](contracts/Evaluator.cairo#L533) en el evaluador para probar que su código funciona (2 pts)


### Ejercicio 16 y 17 - Seguimiento de depósitos con una envoltura ERC20

- Cree e implemente un nuevo ERC20 `ExerciseSolutionToken` para rastrear el depósito del usuario. Este ERC20 debe ser minable y la autorización de mint otorgada a `ExerciseSolution`
- Implemente `ExerciseSolutionToken` y asegúrese de que `ExerciseSolution` conozca su dirección
- Actualice la función de depósito en `ExerciseSolution` para que los saldos de los usuarios se tokenicen: cuando se realiza un depósito en `ExerciseSolution`, los tokens se acuñan en `ExerciseSolutionToken` y se transfieren a la dirección de depósito
- Implemente su contrato y llame a [`submit_exercise_solution()`](contracts/Evaluator.cairo#L754) en el Evaluador para registrarlo
- Llame a [`ex16_17_deposit_and_mint`](contracts/Evaluator.cairo#L591) en el evaluador para probar que su código funciona (4 pts)


### Ejercicio 18 - Retirar fichas y quemar fichas envueltas

- Actualice la función de retiro `ExerciseSolution` para que use `transferFrom()` en `ExerciseSolutionToken`, queme estos tokens y devuelva los DTK
- Implemente su contrato y llame a [`submit_exercise_solution()`](contracts/Evaluator.cairo#L754) en el Evaluador para registrarlo
- Llame a [`ex18_withdraw_and_burn`](contracts/Evaluator.cairo#L659) en el evaluador para probar que su código funciona (2 pts)

​
## Anexo - Herramientas útiles

### Conversión de datos a y desde decimal

Para convertir datos en fieltro, use el script [`utils.py`](utils.py)
Para abrir Python en modo interactivo después de ejecutar el script.

  ```bash
  python -i utils.py
  ```

  ```python
  >>> str_to_felt('ERC20-101')
  1278752977803006783537
  ```

### Comprobando tu progreso y contando tus puntos

​
Sus puntos se acreditarán en su billetera; aunque esto puede tomar algún tiempo. Si desea controlar su conteo de puntos en tiempo real, ¡también puede ver su saldo en Voyager!
​

- Ve a la [ERC20 counter](https://goerli.voyager.online/contract/0x228c0e6db14052a66901df14a9e8493c0711fa571860d9c62b6952997aae58b#readContract) en voyager, en la pestaña "leer contrato"
- Ingrese su dirección en decimal en la función "balanceOf"

También puede consultar su progreso general [aquí](https://starknet-tutorials.vercel.app)
​

### Estado de la transacción

​
¿Envió una transacción y se muestra como "no detectada" en voyager? Esto puede significar dos cosas:
​

- Su transacción está pendiente y se incluirá en un bloque en breve. Entonces será visible en Voyager.
- Su transacción no fue válida y NO se incluirá en un bloque (no existe una transacción fallida en StarkNet).
​
Puede (y debe) verificar el estado de su transacción con la siguiente URL [https://alpha4.starknet.io/feeder_gateway/get_transaction_receipt?transactionHash=](https://alpha4.starknet.io/feeder_gateway/get_transaction_receipt?transactionHash=)  , donde puede agregar el hash de su transacción.
​

​
