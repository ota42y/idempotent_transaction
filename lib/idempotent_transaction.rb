require 'idempotent_transaction/version'

module IdempotentTransaction
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def register_idempotent_column(*columns)
      @idempotent_columns = columns
    end

    def idempotent_columns
      @idempotent_columns
    end
  end

  def finished?
    @finished ||= record_exist?
  end

  def executed?
    @executed ||= false
  end

  def idempotent_transaction(force: false)
    self.class.transaction do
      yield.tap do
        begin
          save!
        rescue ActiveRecord::RecordNotUnique
          raise ActiveRecord::Rollback unless force
        end

        @finished = true
        @executed = true
      end
    end
  end

  private

    def record_exist?
      self.class.exists?(self.class.idempotent_columns.map { |k| [k, send(k)] }.to_h)
    end
end
