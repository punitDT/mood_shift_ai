/**
 * Logger utility for MoodShift AI Cloud Functions
 *
 * - Dev project (mood-shift-ai-dev): All logs (debug, info, warn, error)
 * - Prod project (mood-shift-ai): Only warn and error logs
 *
 * This reduces Cloud Logging costs in production while maintaining
 * full visibility during development.
 */

const DEV_PROJECT_ID = "mood-shift-ai-dev";
const isDevProject = process.env.GCLOUD_PROJECT === DEV_PROJECT_ID;

// eslint-disable-next-line valid-jsdoc
/** Logger with environment-aware log levels */
export const logger = {
  // ALWAYS logged (both dev & prod) - for errors and exceptions
  error: (message: string, error?: unknown) => {
    if (error instanceof Error) {
      console.error(`[ERROR] ${message}:`, error.message, error.stack);
    } else if (error) {
      console.error(`[ERROR] ${message}:`, JSON.stringify(error));
    } else {
      console.error(`[ERROR] ${message}`);
    }
  },

  // ALWAYS logged (both dev & prod) - for warnings and potential issues
  warn: (message: string, data?: unknown) => {
    if (data !== undefined) {
      console.warn(`[WARN] ${message}:`, typeof data === "object" ? JSON.stringify(data) : data);
    } else {
      console.warn(`[WARN] ${message}`);
    }
  },

  // DEV ONLY - for flow tracking and important steps
  info: (message: string, data?: unknown) => {
    if (isDevProject) {
      if (data !== undefined) {
        console.log(`[INFO] ${message}:`, typeof data === "object" ? JSON.stringify(data) : data);
      } else {
        console.log(`[INFO] ${message}`);
      }
    }
  },

  // DEV ONLY - for detailed debugging
  debug: (message: string, data?: unknown) => {
    if (isDevProject) {
      if (data !== undefined) {
        console.log(`[DEBUG] ${message}:`, typeof data === "object" ? JSON.stringify(data) : data);
      } else {
        console.log(`[DEBUG] ${message}`);
      }
    }
  },

  // DEV ONLY - for logging variables and objects with pretty formatting
  vars: (label: string, obj: object) => {
    if (isDevProject) {
      console.log(`[VARS] ${label}:`, JSON.stringify(obj, null, 2));
    }
  },

  // DEV ONLY - for logging request/response flow
  flow: (step: string, details?: object) => {
    if (isDevProject) {
      const timestamp = new Date().toISOString();
      if (details) {
        console.log(`[FLOW] [${timestamp}] ${step}:`, JSON.stringify(details));
      } else {
        console.log(`[FLOW] [${timestamp}] ${step}`);
      }
    }
  },

  // Check if running in dev environment
  isDevEnvironment: (): boolean => isDevProject,
};

export default logger;

