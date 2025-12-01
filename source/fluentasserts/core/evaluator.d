module fluentasserts.core.evaluator;

import fluentasserts.core.evaluation;
import fluentasserts.core.results;
import fluentasserts.core.message : Message;
import fluentasserts.core.asserts : AssertResult;
import fluentasserts.core.base : TestException;
import fluentasserts.core.serializers;

import std.functional : toDelegate;
import std.conv : to;

alias OperationFunc = IResult[] function(ref Evaluation) @safe nothrow;
alias OperationFuncTrusted = IResult[] function(ref Evaluation) @trusted nothrow;

alias MessageOperationFunc = immutable(Message)[] function(ref Evaluation) @safe nothrow;
alias MessageOperationFuncTrusted = immutable(Message)[] function(ref Evaluation) @trusted nothrow;

alias VoidOperationFunc = void function(ref Evaluation) @safe nothrow;
alias VoidOperationFuncTrusted = void function(ref Evaluation) @trusted nothrow;

@safe struct Evaluator {
    private {
        Evaluation* evaluation;
        IResult[] delegate(ref Evaluation) @safe nothrow operation;
        immutable(Message)[] delegate(ref Evaluation) @safe nothrow messageOperation;
        void delegate(ref Evaluation) @safe nothrow voidOperation;
        int operationType; // 0 = IResult[], 1 = Message[], 2 = void
        int refCount;
    }

    this(ref Evaluation eval, OperationFunc op) @trusted {
        this.evaluation = &eval;
        this.operation = op.toDelegate;
        this.operationType = 0;
        this.refCount = 0;
    }

    this(ref Evaluation eval, MessageOperationFunc op) @trusted {
        this.evaluation = &eval;
        this.messageOperation = op.toDelegate;
        this.operationType = 1;
        this.refCount = 0;
    }

    this(ref Evaluation eval, VoidOperationFunc op) @trusted {
        this.evaluation = &eval;
        this.voidOperation = op.toDelegate;
        this.operationType = 2;
        this.refCount = 0;
    }

    this(ref return scope Evaluator other) {
        this.evaluation = other.evaluation;
        this.operation = other.operation;
        this.messageOperation = other.messageOperation;
        this.voidOperation = other.voidOperation;
        this.operationType = other.operationType;
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

        if (operationType == 2) {
            // Void operation - uses evaluation.result for assertion data
            voidOperation(*evaluation);

            if (!evaluation.hasResult()) {
                return;
            }

            string errorMessage = evaluation.result.toString();

            version (DisableSourceResult) {
            } else {
                errorMessage ~= evaluation.source.toString();
            }

            throw new TestException(errorMessage, evaluation.sourceFile, evaluation.sourceLine);
        } else if (operationType == 1) {
            // Message operation - returns messages
            auto messages = messageOperation(*evaluation);
            if (messages.length == 0) {
                return;
            }

            version (DisableSourceResult) {
            } else {
                messages ~= evaluation.source.toMessages();
            }

            throw new TestException(messages, evaluation.sourceFile, evaluation.sourceLine);
        } else {
            // IResult operation - returns IResult[]
            auto results = operation(*evaluation);

            if (results.length == 0 && !evaluation.hasResult()) {
                return;
            }

            IResult[] allResults;

            if (evaluation.result.message.length > 0) {
                auto chainMessage = new MessageResult();
                chainMessage.data.messages = evaluation.result.message;
                allResults ~= chainMessage;
            }

            allResults ~= results;

            if (evaluation.hasResult()) {
                allResults ~= new AssertResultInstance(evaluation.result);
            }

            version (DisableSourceResult) {
            } else {
                allResults ~= evaluation.getSourceResult();
            }

            throw new TestException(allResults, evaluation.sourceFile, evaluation.sourceLine);
        }
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

        auto results = operation(*evaluation);

        if (evaluation.currentValue.throwable !is null) {
            throw evaluation.currentValue.throwable;
        }

        if (evaluation.expectedValue.throwable !is null) {
            throw evaluation.expectedValue.throwable;
        }

        if (results.length == 0 && !evaluation.hasResult()) {
            return;
        }

        IResult[] allResults;

        if (evaluation.result.message.length > 0) {
            auto chainMessage = new MessageResult();
            chainMessage.data.messages = evaluation.result.message;
            allResults ~= chainMessage;
        }

        allResults ~= results;

        if (evaluation.hasResult()) {
            allResults ~= new AssertResultInstance(evaluation.result);
        }

        version (DisableSourceResult) {
        } else {
            allResults ~= evaluation.getSourceResult();
        }

        throw new TestException(allResults, evaluation.sourceFile, evaluation.sourceLine);
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

        if (results.length == 0 && !evaluation.hasResult()) {
            return;
        }

        IResult[] allResults;

        if (evaluation.result.message.length > 0) {
            auto chainMessage = new MessageResult();
            chainMessage.data.messages = evaluation.result.message;
            allResults ~= chainMessage;
        }

        allResults ~= results;

        if (evaluation.hasResult()) {
            allResults ~= new AssertResultInstance(evaluation.result);
        }

        version (DisableSourceResult) {
        } else {
            allResults ~= evaluation.getSourceResult();
        }

        throw new TestException(allResults, evaluation.sourceFile, evaluation.sourceLine);
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
