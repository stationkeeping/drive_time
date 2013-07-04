require 'spec_helper'
require 'active_record'

module DriveTime

  describe ModelStore do

    class ModelA 
    end

    class ModelB 
    end

    before(:each) do
      @model_store = ModelStore.new
      @model_a = ModelA.new
      @model_b = ModelB.new
    end 

    context 'when models are added' do

      it 'should allow an added model to be retrieved' do
        @model_store.add_model(@model_a, 'model_a')
        @model_store.get_model(ModelA, 'model_a').should == @model_a
      end

      context 'when the same model is added twice' do

        it 'should raise a ModelAddedTwiceError' do
          @model_store.add_model(@model_a, 'model_a')
          expect { @model_store.add_model(@model_a, 'model_a') }.to raise_error(ModelStore::ModelAddedTwiceError) 
        end

      end
    end

    context 'when models are retieved' do

      it 'should raise a NoModelsOfClassInStoreError if no model is stored of the given type' do
         @model_store.add_model(@model_a, 'model_a')
         expect { @model_store.get_model(ModelB, 'model_a') }.to raise_error(ModelStore::NoModelsOfClassInStoreError) 
      end

      it 'should raise a NoModelOfClassWithKeyInStoreError if no model is stored of the given type with the given key' do
         @model_store.add_model(@model_a, 'model_a')
         expect { @model_store.get_model(ModelA, 'model_b') }.to raise_error(ModelStore::NoModelOfClassWithKeyInStoreError) 
      end

    end

  
  end
end