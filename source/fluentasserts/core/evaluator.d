module fluentasserts.core.evaluator;

import fluentasserts.core.evaluation;
import fluentasserts.core.results;
import fluentasserts.core.base : TestException;
import fluentasserts.core.serializers;

import std.functional : toDelegate;
import std.conv : to;

alias OperationFunc = IResult[] function(ref Evaluation) @safe nothrow;
alias OperationFuncTrusted = IResult[] function(ref Evaluation) @trusted nothrow;

@safe struct Evaluator {
    private {
        Evaluation* evaluation;
        IResult[] delegate(ref Evaluation) @safe nothrow operation;
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
        evaluation.message.prependText("Because " ~ reason ~ ", ");
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

        auto results = operation(*evaluation);

        if (evaluation.currentValue.throwable !is null) {
            throw evaluation.currentValue.throwable;
        }

        if (evaluation.expectedValue.throwable !is null) {
            throw evaluation.expectedValue.throwable;
        }

        if (results.length == 0) {
            return;
        }

        version (DisableSourceResult) {
        } else {
            results ~= evaluation.getSourceResult();
        }

        if (evaluation.message !is null) {
            results = evaluation.message ~ results;
        }

        throw new TestException(results, evaluation.sourceFile, evaluation.sourceLine);
    }
}

/// Evaluator for @trusted nothrow operations
@safe struct TrustedEvaluator {
    private {
        Evaluation* evaluation;
        IResult[] delegate(ref Evaluation) @trusted nothrow operation;
        int refCount;
    }

    this(ref Evaluation eval, OperationFuncTrusted op) @trusted {
        this.evaluation = &eval;
        this.operation = op.toDelegate;
        this.refCount = 0;
    }

    this(ref Evaluation eval, OperationFunc op) @trusted {
        this.evaluation = &eval;
        this.operation = cast(IResult[] delegate(ref Evaluation) @trusted nothrow) op.toDelegate;
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
        evaluation.message.prependText("Because " ~ reason ~ ", ");
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

        auto results = operation(*evaluation);

        if (evaluation.currentValue.throwable !is null) {
            throw evaluation.currentValue.throwable;
        }

        if (evaluation.expectedValue.throwable !is null) {
            throw evaluation.expectedValue.throwable;
        }

        if (results.length == 0) {
            return;
        }

        version (DisableSourceResult) {
        } else {
            results ~= evaluation.getSourceResult();
        }

        if (evaluation.message !is null) {
            results = evaluation.message ~ results;
        }

        throw new TestException(results, evaluation.sourceFile, evaluation.sourceLine);
    }
}

/// Evaluator for throwable operations that can chain with withMessage
@safe struct ThrowableEvaluator {
    private {
        Evaluation* evaluation;
        IResult[] delegate(ref Evaluation) @trusted nothrow standaloneOp;
        IResult[] delegate(ref Evaluation) @trusted nothrow withMessageOp;
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
        evaluation.message.addText(" with message");
        return this;
    }

    ThrowableEvaluator withMessage(T)(T message) {
        evaluation.operationName ~= ".withMessage";
        evaluation.message.addText(" with message");

        auto expectedValue = message.evaluate.evaluation;
        foreach (key, value; evaluation.expectedValue.meta) {
            expectedValue.meta[key] = value;
        }
        evaluation.expectedValue = expectedValue;
        () @trusted { evaluation.expectedValue.meta["0"] = SerializerRegistry.instance.serialize(message); }();

        if (evaluation.expectedValue.niceValue) {
            evaluation.message.addText(" ");
            evaluation.message.addValue(evaluation.expectedValue.niceValue);
        } else if (evaluation.expectedValue.strValue) {
            evaluation.message.addText(" ");
            evaluation.message.addValue(evaluation.expectedValue.strValue);
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

        evaluation.message.addText(" equal");
        if (evaluation.expectedValue.niceValue) {
            evaluation.message.addText(" ");
            evaluation.message.addValue(evaluation.expectedValue.niceValue);
        } else if (evaluation.expectedValue.strValue) {
            evaluation.message.addText(" ");
            evaluation.message.addValue(evaluation.expectedValue.strValue);
        }

        chainedWithMessage = true;
        executeOperation(withMessageOp);
        inhibit();
        return this;
    }

    ThrowableEvaluator because(string reason) {
        evaluation.message.prependText("Because " ~ reason ~ ", ");
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
        evaluation.message.addText(" ");
        evaluation.message.addText(toNiceOperation(evaluation.operationName));

        if (evaluation.expectedValue.niceValue) {
            evaluation.message.addText(" ");
            evaluation.message.addValue(evaluation.expectedValue.niceValue);
        } else if (evaluation.expectedValue.strValue) {
            evaluation.message.addText(" ");
            evaluation.message.addValue(evaluation.expectedValue.strValue);
        }
    }

    private void executeOperation(IResult[] delegate(ref Evaluation) @trusted nothrow op) @trusted {
        if (evaluation.isEvaluated) {
            return;
        }
        evaluation.isEvaluated = true;

        auto results = op(*evaluation);

        if (evaluation.currentValue.throwable !is null) {
            throw evaluation.currentValue.throwable;
        }

        if (evaluation.expectedValue.throwable !is null) {
            throw evaluation.expectedValue.throwable;
        }

        if (results.length == 0) {
            return;
        }

        version (DisableSourceResult) {
        } else {
            results ~= evaluation.getSourceResult();
        }

        if (evaluation.message !is null) {
            results = evaluation.message ~ results;
        }

        throw new TestException(results, evaluation.sourceFile, evaluation.sourceLine);
    }
}

private string toNiceOperation(string value) @safe nothrow {
    import std.uni : toLower, isUpper, isLower;

    string newValue;

    foreach (index, ch; value) {
        if (index == 0) {
            newValue ~= ch.toLower;
            continue;
        }

        if (ch == '.') {
            newValue ~= ' ';
            continue;
        }

        if (ch.isUpper && value[index - 1].isLower) {
            newValue ~= ' ';
            newValue ~= ch.toLower;
            continue;
        }

        newValue ~= ch;
    }

    return newValue;
}
