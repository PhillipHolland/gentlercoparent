#!/usr/bin/env python3
"""
Deploy processed knowledge to enhanced Vercel API
This script uploads the structured knowledge base to your enhanced-chat endpoint
"""

import json
import requests
import time
from pathlib import Path

class KnowledgeDeployer:
    def __init__(self):
        self.api_url = "https://gentler-coparent-simple-rag.vercel.app/api/enhanced-chat"
        self.knowledge_dir = "/Users/phillipholland/Documents/GCP-xcodebackups/1.0.12/Gentler Coparent/processed_knowledge"
        self.session = requests.Session()
        self.session.timeout = 60  # Longer timeout for large uploads
    
    def load_knowledge_base(self):
        """Load the complete processed knowledge base"""
        kb_file = Path(self.knowledge_dir) / "knowledge_base_complete.json"
        
        if not kb_file.exists():
            raise FileNotFoundError(f"Knowledge base file not found: {kb_file}")
        
        with open(kb_file, 'r') as f:
            return json.load(f)
    
    def test_api_connectivity(self):
        """Test if the API is accessible"""
        try:
            response = self.session.get(self.api_url)
            print(f"📡 API Status: {response.status_code}")
            return response.status_code in [200, 405]  # 405 is expected for GET on POST endpoint
        except Exception as e:
            print(f"❌ API connectivity test failed: {e}")
            return False
    
    def upload_knowledge_base(self, overwrite=True):
        """Upload the complete knowledge base to the API"""
        print("🚀 Starting knowledge base deployment...")
        
        # Test connectivity first
        if not self.test_api_connectivity():
            print("❌ Cannot connect to API. Deployment aborted.")
            return False
        
        # Load knowledge base
        print("📚 Loading processed knowledge base...")
        try:
            knowledge_base = self.load_knowledge_base()
        except Exception as e:
            print(f"❌ Failed to load knowledge base: {e}")
            return False
        
        # Prepare upload payload
        upload_data = {
            "knowledgeData": knowledge_base,
            "category": "complete_knowledge_base",
            "overwrite": overwrite
        }
        
        print(f"📊 Uploading {knowledge_base['metadata']['total_files']} files with {knowledge_base['metadata']['total_chunks']} chunks...")
        
        # Upload to API
        try:
            start_time = time.time()
            
            response = self.session.put(
                self.api_url,
                json=upload_data,
                headers={'Content-Type': 'application/json'}
            )
            
            upload_time = time.time() - start_time
            
            if response.status_code == 200:
                result = response.json()
                print("✅ Knowledge base uploaded successfully!")
                print(f"   📈 Chunks added: {result.get('chunksAdded', 0)}")
                print(f"   📚 Total chunks: {result.get('totalChunks', 0)}")
                print(f"   🏷️ Categories: {len(result.get('categories', []))}")
                print(f"   🗺️ States: {len(result.get('states', []))}")
                print(f"   ⏱️ Upload time: {upload_time:.2f}s")
                return True
            else:
                error_msg = response.text
                print(f"❌ Upload failed with status {response.status_code}")
                print(f"   Response: {error_msg}")
                return False
                
        except requests.RequestException as e:
            print(f"❌ Network error during upload: {e}")
            return False
        except Exception as e:
            print(f"❌ Unexpected error during upload: {e}")
            return False
    
    def test_enhanced_retrieval(self):
        """Test the enhanced retrieval with some sample queries"""
        test_queries = [
            {
                "message": "What are the custody laws in Texas?",
                "userProfile": {"state": "Texas"}
            },
            {
                "message": "How do I handle communication conflicts with my co-parent?",
                "userProfile": {}
            },
            {
                "message": "What should I do if my ex is not following the visitation schedule?",
                "userProfile": {"state": "California"}
            }
        ]
        
        print("\n🧪 Testing enhanced retrieval...")
        
        for i, query in enumerate(test_queries, 1):
            print(f"\n📝 Test Query {i}: {query['message'][:50]}...")
            
            try:
                response = self.session.post(
                    self.api_url,
                    json=query,
                    headers={'Content-Type': 'application/json'}
                )
                
                if response.status_code == 200:
                    result = response.json()
                    knowledge_used = result.get('knowledgeUsed', [])
                    similarity_scores = result.get('similarityScores', [])
                    confidence = result.get('confidenceScore', 0)
                    
                    print(f"   ✅ Success!")
                    print(f"   📚 Knowledge sources: {len(knowledge_used)}")
                    print(f"   🎯 Confidence: {confidence:.2f}")
                    if knowledge_used:
                        print(f"   📄 Top source: {knowledge_used[0]}")
                else:
                    print(f"   ❌ Failed with status {response.status_code}")
                    print(f"   Response: {response.text[:100]}...")
                    
            except Exception as e:
                print(f"   ❌ Error: {e}")
            
            time.sleep(1)  # Rate limiting
    
    def deploy_and_test(self, overwrite=True, run_tests=True):
        """Complete deployment and testing workflow"""
        print("=" * 60)
        print("🚀 GENTLER COPARENT KNOWLEDGE DEPLOYMENT")
        print("=" * 60)
        
        # Upload knowledge base
        upload_success = self.upload_knowledge_base(overwrite)
        
        if upload_success and run_tests:
            # Test the enhanced system
            self.test_enhanced_retrieval()
        
        print("\n" + "=" * 60)
        if upload_success:
            print("🎉 DEPLOYMENT COMPLETED SUCCESSFULLY!")
            print("Your RAG system now has access to comprehensive co-parenting knowledge!")
        else:
            print("❌ DEPLOYMENT FAILED")
            print("Please check the error messages above and retry.")
        print("=" * 60)
        
        return upload_success

def main():
    """Main execution function"""
    deployer = KnowledgeDeployer()
    
    try:
        # Deploy with full testing
        success = deployer.deploy_and_test(overwrite=True, run_tests=True)
        return success
        
    except Exception as e:
        print(f"❌ Deployment script failed: {e}")
        return False

if __name__ == "__main__":
    main()