# A test framework can raise an Omission error to mark a test
# to be omitted. This may be done for a variety of reasons,
# most commonly to mark a test pending completion.
class Omission < Exception
end

