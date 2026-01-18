export class Logger {
  private static PREFIX: string = '[NjuPlan]';

  static info(...args: string[]): void {
    console.info(Logger.PREFIX, ...args);
  }

  static error(...args: string[]): void {
    console.error(Logger.PREFIX, ...args);
  }

  static debug(...args: string[]): void {
    console.debug(Logger.PREFIX, ...args);
  }
}
