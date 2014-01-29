require "hiera/backend/aws_backend"

class Hiera
  module Backend
    describe Aws_backend do
      before do
        Hiera.stub(:debug)
      end

      describe "#initialize" do
        it "uses AWS credentials from environment or IAM role by default" do
          Config.stub(:[]).with(:aws)
          expect(AWS).to_not receive(:config)
          Aws_backend.new
        end

        it "uses AWS credentials from backend configuration if provided" do
          credentials = {
            :access_key_id     => "some_access_key_id",
            :secret_access_key => "some_secret_access_key"
          }

          Config.stub(:[]).with(:aws).and_return(credentials)
          expect(AWS).to receive(:config).with(credentials)
          Aws_backend.new
        end
      end

      describe "#lookup" do
        let(:backend) { Aws_backend.new }
        let(:key) { "some_key" }
        let(:scope) { { "foo" => "bar" } }
        let(:params) { [key, scope, "", :priority] }

        before do
          Config.stub(:[]).with(:aws)
        end

        it "returns nil if hierarchy is empty" do
          Backend.stub(:datasources)
          expect(backend.lookup(*params)).to be_nil
        end

        it "returns nil if service is unknown" do
          Backend.stub(:datasources).and_yield "aws/unknown_service"
          expect(backend.lookup(*params)).to be_nil
        end

        it "properly forwards lookup to ElastiCache service" do
          Backend.stub(:datasources).and_yield "aws/elasticache"
          expect_any_instance_of(Aws::ElastiCache).to receive(:lookup).with(key, scope)
          backend.lookup(*params)
        end
      end
    end
  end
end
