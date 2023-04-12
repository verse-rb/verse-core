class InMemoryRepository < Verse::Model::Repository::Base
  def filtering
    InMemoryFiltering
  end

  def initialize
    @after_commit_blocks = []
  end

  def transaction(&block)
    if @in_transaction
      yield
    else
      begin
        @in_transaction = true
        trigger_after_commit
        yield
      ensure
        @in_transaction = false
      end
    end
  end

  def after_commit(&block)
    @after_commit_blocks << block
  end

  private def trigger_after_commit
    @after_commit_blocks.each(&:call)
    @after_commit_blocks.clear
  end

end