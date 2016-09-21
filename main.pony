use "collections"
use "time"
use "options"

actor Main
  var _count: U64 = 100_000
  let _env: Env
  var _test: TestDoIt tag = TestNoop

  new create(env: Env) =>
    _env = env
    try
      arguments(env)
    else
      return
    end

    _env.out.print("running " + _count.string() + " iterations with "
      + " Payload " + 
      match _test 
        | let t: TestVal => "val"
        else
          "iso"
        end
       )

    // Create a timer that holds on to Test for 10 seconds.
    // let timers = Timers
    // let timer = Timer(recover iso Notify(t) end, 5_000_000_000)
    // timers(consume timer)

    work()
    // again()

  fun ref arguments(env: Env) ? =>
    var options = Options(env.args)

    options.add("loops", "l", I64Argument)
    options.add("cap", "c", StringArgument)

    for option in options do
      match option
      | ("loops", let arg: I64) => _count = arg.u64()
      | ("cap", let arg: String) =>
        match arg
        | "val" => _test = TestVal
        else
          _test = TestIso
        end
      | let err: ParseError => 
        err.report(env.out)
        error
      end
    end


  fun work() =>
    var n: U64 = 0
    for i in Range(0, _count.usize()) do
      n = n + 1
      _test.do_it()
    end
    _env.out.print("Created " + n.string() + " actors.")


  be again() =>
    """
    """
    _test.do_it()
    if _count > 0 then
      _count = _count - 1
      again()
    end


interface TestDoIt
  be do_it()

actor TestNoop
  be do_it() => None    

actor TestVal
  be do_it() => _ServerConnectionVal.dispatch(Payload)

actor TestIso
  be do_it() => _ServerConnectionIso.dispatch(Payload)


class iso Payload
  var handler: (_ServerConnectionVal | _ServerConnectionIso | None) = None

actor _ServerConnectionVal
  be dispatch(p: Payload) =>
    p.handler = recover this end
    this.answer(consume p) // <-- Pass the Payload that references this _ServerConnection

  be answer(p: Payload val) => None

  
actor _ServerConnectionIso
  be dispatch(p: Payload) =>
    p.handler = recover this end
    this.answer(consume p) // <-- Pass the Payload that references this _ServerConnection

  be answer(p: Payload iso) => None

  
