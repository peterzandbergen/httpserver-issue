use "collections"
use "time"
use "options"

actor Main
  var _count: U64 = 100_000
  let _env: Env
  let t: Test = Test

  new create(env: Env) =>
    _env = env
    try
      arguments(env)
    end

    // Create a timer that holds on to Test for 10 seconds.
    // let timers = Timers
    // let timer = Timer(recover iso Notify(t) end, 5_000_000_000)
    // timers(consume timer)

    work()
    // again()

  fun ref arguments(env: Env) ? =>
    var options = Options(env.args)

    options.add("loops", "l", I64Argument)

    for option in options do
      match option
      | ("loops", let arg: I64) => _count = arg.u64()
      | let err: ParseError => 
        err.report(env.out)
        error
      end
    end


  fun work() =>
    var n: U64 = 0
    for i in Range(0, _count.usize()) do
      n = n + 1
      t.do_it()
    end
    _env.out.print("Created " + n.string() + " actors.")


  be again() =>
    """
    """
    t.do_it()
    if _count > 0 then
      _count = _count - 1
      again()
    end


class Notify is TimerNotify
  let _test: Test tag

  new create(t: Test tag) =>
    _test = t

  fun ref apply(timer: Timer, count: U64): Bool =>
    false

  fun ref cancel(timer: Timer ref) =>
    None


actor Test
  be do_it() => _ServerConnection.dispatch(Payload)


class iso Payload
  var handler: (_ServerConnection | None) = None


actor _ServerConnection
  be dispatch(p: Payload) =>
    p.handler = recover this end
    this.answer(consume p) // <-- Pass the Payload that references this _ServerConnection

  be answer(p: Payload val) => None

  
