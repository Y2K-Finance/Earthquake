"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.parseAggregatedErrors = void 0;
const parseAggregatedErrors = (error) => {
    return error.errors.map((error) => {
        const errorStringified = JSON.stringify(error, null, 2);
        return errorStringified !== "{}" ? errorStringified : error.message;
    });
};
exports.parseAggregatedErrors = parseAggregatedErrors;
//# sourceMappingURL=parse-aggregated-errors.js.map