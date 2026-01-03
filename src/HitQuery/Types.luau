--!strict
export type Connection = {
    Disconnect: (self: Connection) -> (),
}

export type Signal = {
    Connect: (self: Signal, fn: (...any) -> ()) -> Connection,
    Once: (self: Signal, fn: (...any) -> ()) -> Connection,
    Fire: (self: Signal, ...any) -> (),
    Wait: (self: Signal) -> ...any,
    DisconnectAll: (self: Signal) -> (),
}

export type HitboxState = "Active" | "Inactive" | "Destroyed"

export type HitQuery = {
    State: HitboxState,
    Parts: { BasePart },
    OverlapParams: OverlapParams,
    FrameRate: string,

    Enable: (self: HitQuery, time: number) -> (),
    Disable: (self: HitQuery) -> (),
    Destroy: (self: HitQuery) -> (),
    Cooldown: (self: HitQuery, time: number) -> (),
    Once: (self: HitQuery) -> (),
    Wait: (self: HitQuery) -> (),

    PartEntered: Signal,
    PlayerEntered: Signal,
    Completed: Signal,
}

return {}