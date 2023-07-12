declare namespace Thread {
	/**
	 * Spawns the given module, passing the given arguments, and returns the id of the thread
	 * @param executeModule You may want to use the getModuleByTree function to retrieve this
	 * @param args Note that the module cannot return data, so you must pass a SharedTable if you want data back
	 */
	export function spawn<A extends unknown[]>(executeModule: ModuleScript, ...args: A): number;

	/**
	 * Yields until the thread, specified by the id, is completed
	 * @param threadSpecifier A single id or several in an array
	 */
	export function join(threadSpecifier: number | Array<number>): void;

	/**
	 * Function only for the roblox-ts version, retrieves a module from the data returned from $getModuleTree
	 * @param root The first element of the array returned from $getModuleTree
	 * @param parts The second element of the array returned from $getModuleTree
	 */
	export function getModuleByTree(root: Instance, parts: Array<string>): ModuleScript;
}

export = Thread;
