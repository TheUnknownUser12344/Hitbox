--!strict
local Janitor = require(script.Parent.janitor)

type Janitor = typeof(Janitor.new())

export type Connection = {
    Disconnect: (self: Connection) -> (),
}

export type Signal = typeof(require(script.Parent.GoodSignal).new())

export type HitboxState = "Active" | "Inactive" | "OnCooldown"

export type HitQuery = typeof(setmetatable({} :: {
    State: HitboxState,
    Parts: { BasePart },
    OverlapParams: OverlapParams?,
    FrameRate: string | number,

    Enable: (self: HitQuery, time: number) -> (),
    Disable: (self: HitQuery) -> (),
    Destroy: (self: HitQuery) -> (),
    Cooldown: (self: HitQuery, time: number) -> (),
    Once: (self: HitQuery) -> (),
    Wait: (self: HitQuery) -> (),

    new: (Parts: { BasePart }) -> HitQuery,

    _CurrentThread: thread?,
    _t: number,

    _Identify: (self: HitQuery, Part: BasePart, Class: string) -> boolean,
    _Delay: (self: HitQuery) -> boolean,
    _Enabled: (self: HitQuery) -> (),
    _Active: (self: HitQuery, Time: number) -> (),
    _SetState: (self: HitQuery, NewState: HitboxState, ...any) -> (),
    _OnEnter: (self: HitQuery, state: HitboxState, ...any) -> (),
    _OnExit: (self: HitQuery, state: HitboxState) -> (),

    _Janitor: Janitor,
    _PartCache: { BasePart },
    _Heartbeat: RBXScriptConnection?,
    _Destroyed: boolean,
    _Options: string?,

    PartEntered: Signal,
    PlayerEntered: Signal,
    Completed: Signal,
}, {} :: {__index: HitQuery}))
 
return {}