var chai = require('chai');
var chaiHttp = require('chai-http');
var assert = chai.assert;
var expect = chai.expect;
var app = require('../../server'); // Adjust path as needed

chai.use(chaiHttp);

describe('Smoke Test', function() {
  this.timeout(5000); // Set a reasonable timeout for HTTP requests

  it('should get 200 on / (homepage)', function(done) {
    chai.request(app)
      .get('/')
      .end(function(err, res) {
        expect(res).to.have.status(200);
        done();
      });
  });

  it('should get 200 on /catalogue (catalogue API)', function(done) {
    chai.request(app)
      .get('/catalogue')
      .end(function(err, res) {
        expect(res).to.have.status(200);
        expect(res.body).to.be.an('array');
        done();
      });
  });

}); 
