# Thread

Fork of [luau-thread](https://github.com/decimalcubed/luau-thread) for Roblox-ts

The module first must export a function:
```ts
// src/shared/module
export = function(timeToWait: number) {
	task.wait(timeToWait);
	print("waited", timeToWait, "second(s)");
}
```

To first get our module, we can use the new $getModuleTree macro, and the function provided in this library
```ts
import Thread from "@rbxts/luau-thread";

const [root, parts] = $getModuleTree("shared/module");
const module = Thread.getModuleByTree(root, parts);
```

Then, we can spawn it, and wait for it to finish:
```ts
const identifier = Thread.spawn(module, 1);
Thread.join(identifier);

// prints: waited 1 second(s)
```

We can also spawn it multiple times, and wait for all threads to finish:
```ts
const identifiers = [];

for (const i of $range(1, 10)) {
	identifiers.push(Thread.spawn(module, i));
}

Thread.join(identifiers);

// prints: waited 1 second(s)
// ...
// prints: waited 10 seconds(s)
```