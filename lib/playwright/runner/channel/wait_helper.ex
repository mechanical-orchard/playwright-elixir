# SEND ---> {
#   id: 4,
#   guid: 'frame@61e4e80afc2fca01be0896c24a355d17',
#   method: 'goto',
#   params: { url: 'http://localhost:3004/empty.html', waitUntil: 'load' }
# }

# SEND ---> {
#   id: 5,
#   guid: 'page@16e29ead8d97503eebe00b47661dcd73',
#   method: 'waitForEventInfo',
#   params: {
#     info: {
#       waitId: 'b231993d6b1182365c1f9af3e8e0ba45',
#       phase: 'before',
#       event: 'requestfinished'
#     }
#   }
# }

# ---

# SEND ---> {
#   id: 6,
#   guid: 'page@16e29ead8d97503eebe00b47661dcd73',
#   method: 'waitForEventInfo',
#   params: {
#     info: {
#       waitId: 'b231993d6b1182365c1f9af3e8e0ba45',
#       phase: 'log',
#       message: 'waiting for event "requestfinished"'
#     }
#   }
# }

# <--- RECV { id: 5 }

# <--- RECV { id: 6 }

# <--- RECV {
#   guid: 'browser-context@75e14c920ac77efaa237229fa66f0dcd',
#   method: '__create__',
#   params: {
#     type: 'Request',
#     initializer: {
#       frame: [Object],
#       url: 'http://localhost:3004/empty.html',
#       resourceType: 'document',
#       method: 'GET',
#       postData: undefined,
#       headers: [Array],
#       isNavigationRequest: true,
#       redirectedFrom: undefined
#     },
#     guid: 'request@d3a444281a4504e394ec6759764f3f9f'
#   }
# }

# <--- RECV {
#   guid: 'browser-context@75e14c920ac77efaa237229fa66f0dcd',
#   method: 'request',
#   params: {
#     request: { guid: 'request@d3a444281a4504e394ec6759764f3f9f' },
#     page: { guid: 'page@16e29ead8d97503eebe00b47661dcd73' }
#   }
# }

# <--- RECV {
#   guid: 'browser-context@75e14c920ac77efaa237229fa66f0dcd',
#   method: '__create__',
#   params: {
#     type: 'Response',
#     initializer: {
#       request: [Object],
#       url: 'http://localhost:3004/empty.html',
#       status: 200,
#       statusText: 'OK',
#       headers: [Array],
#       timing: [Object]
#     },
#     guid: 'response@ff83becb9dafd4757f73763188a2ee7d'
#   }
# }

# <--- RECV {
#   guid: 'browser-context@75e14c920ac77efaa237229fa66f0dcd',
#   method: 'response',
#   params: {
#     response: { guid: 'response@ff83becb9dafd4757f73763188a2ee7d' },
#     page: { guid: 'page@16e29ead8d97503eebe00b47661dcd73' }
#   }
# }

# <--- RECV {
#   guid: 'frame@61e4e80afc2fca01be0896c24a355d17',
#   method: 'loadstate',
#   params: { remove: 'domcontentloaded' }
# }

# <--- RECV {
#   guid: 'frame@61e4e80afc2fca01be0896c24a355d17',
#   method: 'loadstate',
#   params: { remove: 'load' }
# }

# <--- RECV {
#   guid: 'frame@61e4e80afc2fca01be0896c24a355d17',
#   method: 'navigated',
#   params: {
#     url: 'http://localhost:3004/empty.html',
#     name: '',
#     error: undefined,
#     newDocument: { request: [Object] }
#   }
# }

# <--- RECV {
#   guid: 'browser-context@75e14c920ac77efaa237229fa66f0dcd',
#   method: 'requestFinished',
#   params: {
#     request: { guid: 'request@d3a444281a4504e394ec6759764f3f9f' },
#     response: { guid: 'response@ff83becb9dafd4757f73763188a2ee7d' },
#     responseEndTiming: 5.749,
#     page: { guid: 'page@16e29ead8d97503eebe00b47661dcd73' }
#   }
# }

# SEND ---> {
#   id: 7,
#   guid: 'page@16e29ead8d97503eebe00b47661dcd73',
#   method: 'waitForEventInfo',
#   params: {
#     info: { waitId: 'b231993d6b1182365c1f9af3e8e0ba45', phase: 'after' }
#   }
# }

# <--- RECV {
#   guid: 'frame@61e4e80afc2fca01be0896c24a355d17',
#   method: 'loadstate',
#   params: { add: 'load' }
# }

# <--- RECV {
#   guid: 'page@16e29ead8d97503eebe00b47661dcd73',
#   method: 'load',
#   params: undefined
# }

# <--- RECV {
#   id: 4,
#   result: { response: { guid: 'response@ff83becb9dafd4757f73763188a2ee7d' } }
# }

defmodule Playwright.Runner.Channel.WaitHelper do
  require Logger
  alias Playwright.Runner.Channel

  defstruct [:uuid, :subject, :event, :fun, :listeners]

  def new(subject, event, fun) do
    helper = %__MODULE__{
      uuid: UUID.uuid4(:hex),
      subject: subject,
      event: event,
      fun: fun,
      listeners: []
    }

    fun.(subject)
    |> IO.inspect(label: "fun result")

    Logger.error("WaitHelper... executed fun")

    Channel.send(
      subject,
      "waitForEventInfo",
      %{
        info: %{
          waitId: helper.uuid,
          phase: "before",
          event: event
        }
      },
      :noreply
    )

    Logger.error("WaitHelper... sent waitForEventInfo:before")

    helper
  end

  def wait_for_event(%{subject: subject} = helper) do
    #  def listener(event_data: Any = None) -> None:
    #      if not predicate or predicate(event_data):
    #          self._fulfill(event_data)
    #
    #  emitter.on(event, listener)
    #  self._registered_listeners.append((emitter, event, listener))

    GenServer.call(subject.connection, {:on, {helper.event, subject}, fn (resource, event) ->
      Logger.error("wait_for_event on w/ resource: #{inspect(resource)} and event: #{inspect(event)}")
    end})
  end
#     def _cleanup(self) -> None:
#         for task in self._pending_tasks:
#             if not task.done():
#                 task.cancel()
#         for listener in self._registered_listeners:
#             listener[0].remove_listener(listener[1], listener[2])

#     def _fulfill(self, result: Any) -> None:
#         self._cleanup()
#         if not self._result.done():
#             self._result.set_result(result)
#         self._wait_for_event_info_after(self._wait_id)

#     def _reject(self, exception: Exception) -> None:
#         self._cleanup()
#         if exception:
#             base_class = TimeoutError if isinstance(exception, TimeoutError) else Error
#             exception = base_class(str(exception) + format_log_recording(self._logs))
#         if not self._result.done():
#             self._result.set_exception(exception)
#         self._wait_for_event_info_after(self._wait_id, exception)

#     def wait_for_event(
#         self,
#         emitter: EventEmitter,
#         event: str,
#         predicate: Callable = None,
#     ) -> None:
#         def listener(event_data: Any = None) -> None:
#             if not predicate or predicate(event_data):
#                 self._fulfill(event_data)
#
#         emitter.on(event, listener)
#         self._registered_listeners.append((emitter, event, listener))
end

# // BrowserContext
# async waitForEvent(event: string, optionsOrPredicate: WaitForEventOptions = {}): Promise<any> {
#   return this._wrapApiCall(async (channel: channels.BrowserContextChannel) => {
#     const timeout = this._timeoutSettings.timeout(typeof optionsOrPredicate === 'function'  ? {} : optionsOrPredicate);
#     const predicate = typeof optionsOrPredicate === 'function'  ? optionsOrPredicate : optionsOrPredicate.predicate;
#     const waiter = Waiter.createForEvent(channel, event);
#     waiter.rejectOnTimeout(timeout, `Timeout while waiting for event "${event}"`);
#     if (event !== Events.BrowserContext.Close)
#       waiter.rejectOnEvent(this, Events.BrowserContext.Close, new Error('Context closed'));
#     const result = await waiter.waitForEvent(this, event, predicate as any);
#     waiter.dispose();
#     return result;
#   });
# }

# import { EventEmitter } from 'events';
# import { rewriteErrorMessage } from '../utils/stackTrace';
# import { TimeoutError } from '../utils/errors';
# import { createGuid } from '../utils/utils';
# import * as channels from '../protocol/channels';

# export class Waiter {
#   private _dispose: (() => void)[];
#   private _failures: Promise<any>[] = [];
#   private _immediateError?: Error;
#   // TODO: can/should we move these logs into wrapApiCall?
#   private _logs: string[] = [];
#   private _channel: channels.EventTargetChannel;
#   private _waitId: string;
#   private _error: string | undefined;

#   constructor(channel: channels.EventTargetChannel, event: string) {
#     this._waitId = createGuid();
#     this._channel = channel;
#     this._channel.waitForEventInfo({ info: { waitId: this._waitId, phase: 'before', event } }).catch(() => {});
#     this._dispose = [
#       () => this._channel.waitForEventInfo({ info: { waitId: this._waitId, phase: 'after', error: this._error } }).catch(() => {})
#     ];
#   }

#   static createForEvent(channel: channels.EventTargetChannel, event: string) {
#     return new Waiter(channel, event);
#   }

#   async waitForEvent<T = void>(emitter: EventEmitter, event: string, predicate?: (arg: T) => boolean | Promise<boolean>): Promise<T> {
#     const { promise, dispose } = waitForEvent(emitter, event, predicate);
#     return this.waitForPromise(promise, dispose);
#   }

#   rejectOnEvent<T = void>(emitter: EventEmitter, event: string, error: Error, predicate?: (arg: T) => boolean | Promise<boolean>) {
#     const { promise, dispose } = waitForEvent(emitter, event, predicate);
#     this._rejectOn(promise.then(() => { throw error; }), dispose);
#   }

#   rejectOnTimeout(timeout: number, message: string) {
#     if (!timeout)
#       return;
#     const { promise, dispose } = waitForTimeout(timeout);
#     this._rejectOn(promise.then(() => { throw new TimeoutError(message); }), dispose);
#   }

#   rejectImmediately(error: Error) {
#     this._immediateError = error;
#   }

#   dispose() {
#     for (const dispose of this._dispose)
#       dispose();
#   }

#   async waitForPromise<T>(promise: Promise<T>, dispose?: () => void): Promise<T> {
#     try {
#       if (this._immediateError)
#         throw this._immediateError;
#       const result = await Promise.race([promise, ...this._failures]);
#       if (dispose)
#         dispose();
#       return result;
#     } catch (e) {
#       if (dispose)
#         dispose();
#       this._error = e.message;
#       this.dispose();
#       rewriteErrorMessage(e, e.message + formatLogRecording(this._logs));
#       throw e;
#     }
#   }

#   log(s: string) {
#     this._logs.push(s);
#     this._channel.waitForEventInfo({ info: { waitId: this._waitId, phase: 'log', message: s } }).catch(() => {});
#   }

#   private _rejectOn(promise: Promise<any>, dispose?: () => void) {
#     this._failures.push(promise);
#     if (dispose)
#       this._dispose.push(dispose);
#   }
# }

# function waitForEvent<T = void>(emitter: EventEmitter, event: string, predicate?: (arg: T) => boolean | Promise<boolean>): { promise: Promise<T>, dispose: () => void } {
#   let listener: (eventArg: any) => void;
#   const promise = new Promise<T>((resolve, reject) => {
#     listener = async (eventArg: any) => {
#       try {
#         if (predicate && !(await predicate(eventArg)))
#           return;
#         emitter.removeListener(event, listener);
#         resolve(eventArg);
#       } catch (e) {
#         emitter.removeListener(event, listener);
#         reject(e);
#       }
#     };
#     emitter.addListener(event, listener);
#   });
#   const dispose = () => emitter.removeListener(event, listener);
#   return { promise, dispose };
# }

# function waitForTimeout(timeout: number): { promise: Promise<void>, dispose: () => void } {
#   let timeoutId: any;
#   const promise = new Promise<void>(resolve => timeoutId = setTimeout(resolve, timeout));
#   const dispose = () => clearTimeout(timeoutId);
#   return { promise, dispose };
# }

# function formatLogRecording(log: string[]): string {
#   if (!log.length)
#     return '';
#   const header = ` logs `;
#   const headerLength = 60;
#   const leftLength = (headerLength - header.length) / 2;
#   const rightLength = headerLength - header.length - leftLength;
#   return `\n${'='.repeat(leftLength)}${header}${'='.repeat(rightLength)}\n${log.join('\n')}\n${'='.repeat(headerLength)}`;
# }

# ----------------------------

# import asyncio
# import math
# import uuid
# from asyncio.tasks import Task
# from typing import Any, Callable, List, Tuple

# from pyee import EventEmitter

# from playwright._impl._api_types import Error, TimeoutError
# from playwright._impl._connection import ChannelOwner

# class WaitHelper:
#     def __init__(self, channel_owner: ChannelOwner, event: str) -> None:
#         self._result: asyncio.Future = asyncio.Future()
#         self._wait_id = uuid.uuid4().hex
#         self._loop = channel_owner._loop
#         self._pending_tasks: List[Task] = []
#         self._channel = channel_owner._channel
#         self._registered_listeners: List[Tuple[EventEmitter, str, Callable]] = []
#         self._logs: List[str] = []
#         self._wait_for_event_info_before(self._wait_id, event)

#     def _wait_for_event_info_before(self, wait_id: str, event: str) -> None:
#         self._channel.send_no_reply(
#             "waitForEventInfo",
#             {
#                 "info": {
#                     "waitId": wait_id,
#                     "phase": "before",
#                     "event": event,
#                 }
#             },
#         )

#     def _wait_for_event_info_after(self, wait_id: str, error: Exception = None) -> None:
#         try:
#             info = {
#                 "waitId": wait_id,
#                 "phase": "after",
#             }
#             if error:
#                 info["error"] = str(error)
#             self._channel.send_no_reply(
#                 "waitForEventInfo",
#                 {
#                     "info": info,
#                 },
#             )
#         except Exception:
#             pass

#     def reject_on_event(
#         self,
#         emitter: EventEmitter,
#         event: str,
#         error: Error,
#         predicate: Callable = None,
#     ) -> None:
#         def listener(event_data: Any = None) -> None:
#             if not predicate or predicate(event_data):
#                 self._reject(error)

#         emitter.on(event, listener)
#         self._registered_listeners.append((emitter, event, listener))

#     def reject_on_timeout(self, timeout: float, message: str) -> None:
#         if timeout == 0:
#             return

#         async def reject() -> None:
#             await asyncio.sleep(timeout / 1000)
#             self._reject(TimeoutError(message))

#         self._pending_tasks.append(self._loop.create_task(reject()))

#     def _cleanup(self) -> None:
#         for task in self._pending_tasks:
#             if not task.done():
#                 task.cancel()
#         for listener in self._registered_listeners:
#             listener[0].remove_listener(listener[1], listener[2])

#     def _fulfill(self, result: Any) -> None:
#         self._cleanup()
#         if not self._result.done():
#             self._result.set_result(result)
#         self._wait_for_event_info_after(self._wait_id)

#     def _reject(self, exception: Exception) -> None:
#         self._cleanup()
#         if exception:
#             base_class = TimeoutError if isinstance(exception, TimeoutError) else Error
#             exception = base_class(str(exception) + format_log_recording(self._logs))
#         if not self._result.done():
#             self._result.set_exception(exception)
#         self._wait_for_event_info_after(self._wait_id, exception)

#     def wait_for_event(
#         self,
#         emitter: EventEmitter,
#         event: str,
#         predicate: Callable = None,
#     ) -> None:
#         def listener(event_data: Any = None) -> None:
#             if not predicate or predicate(event_data):
#                 self._fulfill(event_data)

#         emitter.on(event, listener)
#         self._registered_listeners.append((emitter, event, listener))

#     def result(self) -> asyncio.Future:
#         return self._result

#     def log(self, message: str) -> None:
#         self._logs.append(message)
#         try:
#             self._channel.send_no_reply(
#                 "waitForEventInfo",
#                 {
#                     "info": {
#                         "waitId": self._wait_id,
#                         "phase": "log",
#                         "message": message,
#                     },
#                 },
#             )
#         except Exception:
#             pass

# def throw_on_timeout(timeout: float, exception: Exception) -> asyncio.Task:
#     async def throw() -> None:
#         await asyncio.sleep(timeout / 1000)
#         raise exception

#     return asyncio.create_task(throw())

# def format_log_recording(log: List[str]) -> str:
#     if not log:
#         return ""
#     header = " logs "
#     header_length = 60
#     left_length = math.floor((header_length - len(header)) / 2)
#     right_length = header_length - len(header) - left_length
#     new_line = "\n"
#     return f"{new_line}{'=' * left_length}{header}{'=' * right_length}{new_line}{new_line.join(log)}{new_line}{'=' * header_length}"
