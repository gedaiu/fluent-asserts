/// Evaluator structs for executing assertion operations.
/// Provides lifetime management and result handling for assertions.
module fluentasserts.core.evaluator;

import fluentasserts.core.evaluation;
import fluentasserts.core.lifecycle;
import fluentasserts.results.printer;
import fluentasserts.core.base : TestException;
import fluentasserts.results.serializers;
import fluentasserts.results.formatting : toNiceOperation;

import std.functional : toDelegate;
import std.conv : to;

alias OperationFunc = void function(ref Evaluation) @safe nothrow;
alias OperationFuncTrusted = void function(ref Evaluation) @trusted nothrow;

@safe struct Evaluator {
    private {
        Evaluation* evaluation;
        void delegate(ref Evaluation) @safe nothrow operation;
        int refCount;
    }

    this(ref Evaluation eval, OperationFunc op) @trusted {
        this.evaluation = &eval;
        this.operation = op.toDelegate;
        this.refCount = 0;
    }

    this(ref return scope Evaluator other) {
        this.evaluation = other.evaluation;
        this.operation = other.operation;
        this.refCount = other.refCount + 1;
    }

    ~this() @trusted {
        refCount--;
        if (refCount < 0 && evaluation !is null) {
            executeOperation();
        }
    }

    Evaluator because(string reason) {
        evaluation.result.prependText("Because " ~ reason ~ ", ");
        return this;
    }

    void inhibit() {
        this.refCount = int.max;
    }

    Throwable thrown() @trusted {
        executeOperation();
        return evaluation.throwable;
    }

    string msg() @trusted {
        executeOperation();
        if (evaluation.throwable is null) {
            return "";
        }
        return evaluation.throwable.msg.to!string;
    }

    private void executeOperation() @trusted {
        if (evaluation.isEvaluated) {
            return;
        }
        evaluation.isEvaluated = true;

        if (evaluation.currentValue.throwable !is null) {
            throw evaluation.currentValue.throwable;
        }

        if (evaluation.expectedValue.throwable !is null) {
            throw evaluation.expectedValue.throwable;
        }

        operation(*evaluation);

        if (Lifecycle.instance.keepLastEvaluation) {
            Lifecycle.instance.lastEvaluation = *evaluation;
        }

        if (!evaluation.hasResult()) {
            return;
        }

        Lifecycle.instance.handleFailure(*evaluation);
    }
}

/// Evaluator for @trusted nothrow operations
@safe struct TrustedEvaluator {
    private {
        Evaluation* evaluation;
        void delegate(ref Evaluation) @trusted nothrow operation;
        int refCount;
    }

    this(ref Evaluation eval, OperationFuncTrusted op) @trusted {
        this.evaluation = &eval;
        this.operation = op.toDelegate;
        this.refCount = 0;
    }

    this(ref Evaluation eval, OperationFunc op) @trusted {
        this.evaluation = &eval;
        this.operation = cast(void delegate(ref Evaluation) @trusted nothrow) op.toDelegate;
        this.refCount = 0;
    }

    this(ref return scope TrustedEvaluator other) {
        this.evaluation = other.evaluation;
        this.operation = other.operation;
        this.refCount = other.refCount + 1;
    }

    ~this() @trusted {
        refCount--;
        if (refCount < 0 && evaluation !is null) {
            executeOperation();
        }
    }

    TrustedEvaluator because(string reason) {
        evaluation.result.prependText("Because " ~ reason ~ ", ");
        return this;
    }

    void inhibit() {
        this.refCount = int.max;
    }

    private void executeOperation() @trusted {
        if (evaluation.isEvaluated) {
            return;
        }
        evaluation.isEvaluated = true;

        operation(*evaluation);

        if (evaluation.currentValue.throwable !is null) {
            throw evaluation.currentValue.throwable;
        }

        if (evaluation.expectedValue.throwable !is null) {
            throw evaluation.expectedValue.throwable;
        }

        if (Lifecycle.instance.keepLastEvaluation) {
            Lifecycle.instance.lastEvaluation = *evaluation;
        }

        if (!evaluation.hasResult()) {
            return;
        }

        Lifecycle.instance.handleFailure(*evaluation);
    }
}

/// Evaluator for throwable operations that can chain with withMessage
@safe struct ThrowableEvaluator {
    private {
        Evaluation* evaluation;
        void delegate(ref Evaluation) @trusted nothrow standaloneOp;
        void delegate(ref Evaluation) @trusted nothrow withMessageOp;
        int refCount;
        bool chainedWithMessage;
    }

    this(ref Evaluation eval, OperationFuncTrusted standalone, OperationFuncTrusted withMsg) @trusted {
        this.evaluation = &eval;
        this.standaloneOp = standalone.toDelegate;
        this.withMessageOp = withMsg.toDelegate;
        this.refCount = 0;
        this.chainedWithMessage = false;
    }

    this(ref return scope ThrowableEvaluator other) {
        this.evaluation = other.evaluation;
        this.standaloneOp = other.standaloneOp;
        this.withMessageOp = other.withMessageOp;
        this.refCount = other.refCount + 1;
        this.chainedWithMessage = other.chainedWithMessage;
    }

    ~this() @trusted {
        refCount--;
        if (refCount < 0 && !chainedWithMessage && evaluation !is null) {
            executeOperation(standaloneOp);
        }
    }

    ThrowableEvaluator withMessage() {
        evaluation.operationName ~= ".withMessage";
        evaluation.result.addText(" with message");
        return this;
    }

    ThrowableEvaluator withMessage(T)(T message) {
        evaluation.operationName ~= ".withMessage";
        evaluation.result.addText(" with message");

        auto expectedValue = message.evaluate.evaluation;
        foreach (key, value; evaluation.expectedValue.meta) {
            expectedValue.meta[key] = value;
        }
        evaluation.expectedValue = expectedValue;
        () @trusted { evaluation.expectedValue.meta["0"] = SerializerRegistry.instance.serialize(message); }();

        if (evaluation.expectedValue.niceValue) {
            evaluation.result.addText(" ");
            evaluation.result.addValue(evaluation.expectedValue.niceValue);
        } else if (evaluation.expectedValue.strValue) {
            evaluation.result.addText(" ");
            evaluation.result.addValue(evaluation.expectedValue.strValue);
        }

        chainedWithMessage = true;
        executeOperation(withMessageOp);
        inhibit();
        return this;
    }

    ThrowableEvaluator equal(T)(T value) {
        evaluation.operationName ~= ".equal";

        auto expectedValue = value.evaluate.evaluation;
        foreach (key, v; evaluation.expectedValue.meta) {
            expectedValue.meta[key] = v;
        }
        evaluation.expectedValue = expectedValue;
        () @trusted { evaluation.expectedValue.meta["0"] = SerializerRegistry.instance.serialize(value); }();

        evaluation.result.addText(" equal");
        if (evaluation.expectedValue.niceValue) {
            evaluation.result.addText(" ");
            evaluation.result.addValue(evaluation.expectedValue.niceValue);
        } else if (evaluation.expectedValue.strValue) {
            evaluation.result.addText(" ");
            evaluation.result.addValue(evaluation.expectedValue.strValue);
        }

        chainedWithMessage = true;
        executeOperation(withMessageOp);
        inhibit();
        return this;
    }

    ThrowableEvaluator because(string reason) {
        evaluation.result.prependText("Because " ~ reason ~ ", ");
        return this;
    }

    void inhibit() {
        this.refCount = int.max;
    }

    Throwable thrown() @trusted {
        executeOperation(standaloneOp);
        return evaluation.throwable;
    }

    string msg() @trusted {
        executeOperation(standaloneOp);
        if (evaluation.throwable is null) {
            return "";
        }
        return evaluation.throwable.msg.to!string;
    }

    private void finalizeMessage() {
        evaluation.result.addText(" ");
        evaluation.result.addText(toNiceOperation(evaluation.operationName));

        if (evaluation.expectedValue.niceValue) {
            evaluation.result.addText(" ");
            evaluation.result.addValue(evaluation.expectedValue.niceValue);
        } else if (evaluation.expectedValue.strValue) {
            evaluation.result.addText(" ");
            evaluation.result.addValue(evaluation.expectedValue.strValue);
        }
    }

    private void executeOperation(void delegate(ref Evaluation) @trusted nothrow op) @trusted {
        if (evaluation.isEvaluated) {
            return;
        }
        evaluation.isEvaluated = true;

        op(*evaluation);

        if (evaluation.currentValue.throwable !is null) {
            throw evaluation.currentValue.throwable;
        }

        if (evaluation.expectedValue.throwable !is null) {
            throw evaluation.expectedValue.throwable;
        }

        if (Lifecycle.instance.keepLastEvaluation) {
            Lifecycle.instance.lastEvaluation = *evaluation;
        }

        if (!evaluation.hasResult()) {
            return;
        }

        Lifecycle.instance.handleFailure(*evaluation);
    }
}
