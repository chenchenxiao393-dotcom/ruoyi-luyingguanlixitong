<template>
  <div class="equipment-portal-container">
    <!-- 页面头部 -->
    <div class="portal-header">
      <div class="header-content">
        <h2 class="page-title">装备租赁</h2>
        <p class="page-desc">一站式户外装备租赁，轻装出行</p>
      </div>
    </div>

    <!-- 分类导航 -->
    <div class="category-nav">
      <div
        class="category-item"
        :class="{ active: activeCategory === '' }"
        @click="switchCategory('')"
      >
        <i class="el-icon-menu"></i>
        <span>全部</span>
      </div>
      <div
        v-for="cat in categoryList"
        :key="cat.id"
        class="category-item"
        :class="{ active: activeCategory === String(cat.id) }"
        @click="switchCategory(String(cat.id))"
      >
        <i :class="cat.icon || 'el-icon-s-goods'"></i>
        <span>{{ cat.categoryName }}</span>
      </div>
    </div>

    <!-- 装备列表 -->
    <div class="equipment-list" v-loading="loading">
      <el-empty v-if="!loading && equipmentList.length === 0" description="暂无装备" :image-size="100">
        <i slot="image" class="el-icon-suitcase empty-icon"></i>
      </el-empty>

      <div class="equipment-grid">
        <div
          v-for="item in equipmentList"
          :key="item.id"
          class="equipment-card"
          @click="showDetail(item)"
        >
          <div class="card-image">
            <div class="img-placeholder" v-if="!item.equipImages">
              <i class="el-icon-camera"></i>
            </div>
            <img v-else :src="item.equipImages.split(',')[0]" :alt="item.equipName" />
            <div class="card-category-tag">{{ item.categoryName }}</div>
          </div>
          <div class="card-info">
            <h3 class="equip-name">{{ item.equipName }}</h3>
            <p class="equip-desc" v-if="item.equipDesc">{{ item.equipDesc }}</p>
            <div class="equip-meta">
              <span class="stock" :class="(item.stock || 0) > 0 ? 'in-stock' : 'out-stock'">
                <i :class="(item.stock || 0) > 0 ? 'el-icon-circle-check' : 'el-icon-circle-close'"></i>
                {{ (item.stock || 0) > 0 ? '可租赁' : '已租罄' }}
              </span>
              <span class="unit">单位：{{ item.unit || '件' }}</span>
            </div>
            <div class="price-row">
              <span class="price">¥{{ item.price || 0 }}</span>
              <span class="per-unit">/{{ item.unit || '件' }}</span>
              <el-button
                size="mini"
                type="primary"
                class="rent-btn"
                :disabled="(item.stock || 0) <= 0"
                @click.stop="showDetail(item)"
              >我要租赁</el-button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- 分页 -->
    <div class="pagination-wrapper" v-if="total > 0">
      <el-pagination
        @size-change="handleSizeChange"
        @current-change="handleCurrentChange"
        :current-page="queryParams.pageNum"
        :page-sizes="[8, 12, 16]"
        :page-size="queryParams.pageSize"
        layout="total, sizes, prev, pager, next, jumper"
        :total="total"
      />
    </div>

    <!-- 装备详情弹窗 -->
    <el-dialog
      :title="detailData.equipName"
      :visible.sync="detailVisible"
      width="640px"
      class="equip-detail-dialog"
      :close-on-click-modal="false"
    >
      <div class="detail-body" v-if="detailData.id">
        <div class="detail-image">
          <div class="img-placeholder-lg" v-if="!detailData.equipImages">
            <i class="el-icon-camera"></i>
          </div>
          <img v-else :src="detailData.equipImages.split(',')[0]" />
        </div>
        <div class="detail-info">
          <div class="info-row">
            <span class="label">分类</span>
            <span class="value">{{ detailData.categoryName }}</span>
          </div>
          <div class="info-row">
            <span class="label">价格</span>
            <span class="value price">¥{{ detailData.price || 0 }}/{{ detailData.unit || '件' }}</span>
          </div>
          <div class="info-row">
            <span class="label">库存</span>
            <span class="value" :class="(detailData.stock || 0) > 0 ? 'in-stock' : 'out-stock'">
              {{ (detailData.stock || 0) > 0 ? '剩余 ' + detailData.stock + ' ' + (detailData.unit || '件') : '已租罄' }}
            </span>
          </div>
          <div class="info-row" v-if="detailData.equipDesc">
            <span class="label">描述</span>
            <span class="value">{{ detailData.equipDesc }}</span>
          </div>
        </div>
        <div class="rent-section" v-if="(detailData.stock || 0) > 0">
          <div class="rent-title">选择租赁数量</div>
          <div class="rent-control">
            <el-input-number v-model="rentQuantity" :min="1" :max="detailData.stock" size="small" />
            <span class="rent-total">
              小计：<span class="total-price">¥{{ (rentQuantity * (detailData.price || 0)).toFixed(2) }}</span>
            </span>
          </div>
          <el-button type="primary" class="rent-submit-btn" @click="handleRent(detailData)" :loading="rentLoading">
            <i class="el-icon-shopping-cart-2"></i> 立即租赁
          </el-button>
        </div>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import { listEquipmentCategory } from "@/api/system/equipmentCategory"
import { listEquipment, getEquipment } from "@/api/system/equipment"
import { createOrder } from "@/api/system/order"

export default {
  name: "EquipmentRental",
  data() {
    return {
      categoryList: [],
      equipmentList: [],
      total: 0,
      loading: false,
      activeCategory: '',
      queryParams: {
        pageNum: 1,
        pageSize: 8,
        status: '0'
      },
      // 详情弹窗
      detailVisible: false,
      detailData: {},
      rentQuantity: 1,
      rentLoading: false
    }
  },
  created() {
    this.loadCategories()
    this.getList()
  },
  methods: {
    // 加载分类
    loadCategories() {
      listEquipmentCategory({}).then(response => {
        this.categoryList = response.rows || []
      }).catch(() => {})
    },
    // 获取列表
    getList() {
      this.loading = true
      const params = { ...this.queryParams }
      if (this.activeCategory) {
        params.categoryId = this.activeCategory
      }
      listEquipment(params).then(response => {
        this.equipmentList = response.rows || []
        this.total = response.total || 0
      }).catch(() => {
        this.equipmentList = []
        this.total = 0
      }).finally(() => {
        this.loading = false
      })
    },
    // 切换分类
    switchCategory(catId) {
      this.activeCategory = catId
      this.queryParams.pageNum = 1
      this.getList()
    },
    handleSizeChange(val) {
      this.queryParams.pageSize = val
      this.getList()
    },
    handleCurrentChange(val) {
      this.queryParams.pageNum = val
      this.getList()
    },
    // 展示详情
    showDetail(item) {
      this.rentQuantity = 1
      getEquipment(item.id).then(response => {
        this.detailData = response.data || item
        this.detailVisible = true
      }).catch(() => {
        this.detailData = item
        this.detailVisible = true
      })
    },
    // 租赁
    handleRent(item) {
      this.rentLoading = true
      // 创建装备租赁订单
      const orderData = {
        campName: '装备租赁',
        siteName: item.equipName,
        siteType: item.categoryName,
        totalAmount: (this.rentQuantity * (item.price || 0)).toFixed(2),
        contactName: '用户',
        contactPhone: '13800000000',
        remark: `租赁装备：${item.equipName} x ${this.rentQuantity}`
      }
      createOrder(orderData).then(() => {
        this.$message.success('租赁订单已创建，请到我的订单中支付！')
        this.detailVisible = false
      }).catch(() => {
        this.$message.error('租赁失败，请重试')
      }).finally(() => {
        this.rentLoading = false
      })
    }
  }
}
</script>

<style scoped lang="scss">
.equipment-portal-container {
  padding: 0 0 40px;
  background: #f5f7fa;
  min-height: calc(100vh - 84px);
}

// 页面头部
.portal-header {
  background: linear-gradient(135deg, #e67e22, #f39c12);
  padding: 40px 40px 50px;
  text-align: center;
  position: relative;
  overflow: hidden;

  &::before {
    content: '';
    position: absolute;
    top: -50%;
    left: -50%;
    width: 200%;
    height: 200%;
    background: radial-gradient(circle at 70% 30%, rgba(255,255,255,0.15) 0%, transparent 50%);
  }

  .header-content { position: relative; z-index: 1; }

  .page-title {
    font-size: 32px;
    font-weight: 700;
    color: #fff;
    margin: 0 0 8px;
    letter-spacing: 2px;
  }

  .page-desc {
    font-size: 15px;
    color: rgba(255,255,255,0.85);
    margin: 0;
  }
}

// 分类导航
.category-nav {
  display: flex;
  gap: 8px;
  max-width: 1200px;
  margin: -22px auto 24px;
  padding: 0 20px;
  overflow-x: auto;
  position: relative;
  z-index: 2;

  .category-item {
    display: flex;
    align-items: center;
    gap: 6px;
    padding: 10px 20px;
    background: #fff;
    border-radius: 10px;
    font-size: 14px;
    color: #4e5969;
    cursor: pointer;
    white-space: nowrap;
    box-shadow: 0 2px 8px rgba(0,0,0,0.06);
    transition: all 0.3s;
    user-select: none;

    i { font-size: 16px; }

    &:hover { color: #e67e22; }

    &.active {
      background: #e67e22;
      color: #fff;
      box-shadow: 0 4px 12px rgba(230,126,34,0.3);
    }
  }
}

// 装备网格
.equipment-list {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 20px;
  min-height: 300px;
}

.equipment-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 20px;
}

.equipment-card {
  background: #fff;
  border-radius: 12px;
  overflow: hidden;
  cursor: pointer;
  transition: all 0.3s;
  border: 1px solid #f2f3f5;
  box-shadow: 0 2px 8px rgba(0,0,0,0.04);

  &:hover {
    transform: translateY(-4px);
    box-shadow: 0 12px 32px rgba(0,0,0,0.12);
    border-color: transparent;
  }

  .card-image {
    position: relative;
    height: 180px;
    background: #f2f3f5;
    overflow: hidden;

    img {
      width: 100%;
      height: 100%;
      object-fit: cover;
      transition: transform 0.5s;
    }

    &:hover img { transform: scale(1.08); }

    .img-placeholder {
      width: 100%;
      height: 100%;
      display: flex;
      align-items: center;
      justify-content: center;
      background: linear-gradient(135deg, #fef3e8, #fde8d0);

      i { font-size: 40px; color: #e67e22; opacity: 0.4; }
    }

    .card-category-tag {
      position: absolute;
      top: 12px;
      left: 12px;
      padding: 4px 10px;
      background: rgba(0,0,0,0.5);
      color: #fff;
      font-size: 12px;
      border-radius: 4px;
      backdrop-filter: blur(4px);
    }
  }

  .card-info {
    padding: 16px;

    .equip-name {
      font-size: 16px;
      font-weight: 600;
      color: #1d2129;
      margin: 0 0 6px;
    }

    .equip-desc {
      font-size: 13px;
      color: #86909c;
      line-height: 1.5;
      margin: 0 0 10px;
      display: -webkit-box;
      -webkit-line-clamp: 2;
      -webkit-box-orient: vertical;
      overflow: hidden;
    }

    .equip-meta {
      display: flex;
      justify-content: space-between;
      font-size: 12px;
      margin-bottom: 10px;

      .stock {
        display: flex;
        align-items: center;
        gap: 4px;

        i { font-size: 13px; }

        &.in-stock { color: #67c23a; }
        &.out-stock { color: #c9cdd4; }
      }

      .unit { color: #c9cdd4; }
    }

    .price-row {
      display: flex;
      align-items: center;
      gap: 4px;
      padding-top: 10px;
      border-top: 1px solid #f2f3f5;

      .price {
        font-size: 20px;
        font-weight: 700;
        color: #f56c6c;
      }

      .per-unit {
        flex: 1;
        font-size: 12px;
        color: #86909c;
      }

      .rent-btn {
        border-radius: 6px;
      }
    }
  }
}

// 分页
.pagination-wrapper {
  display: flex;
  justify-content: center;
  padding: 32px 0 0;
}

// 空状态
.empty-icon {
  font-size: 60px;
  color: #c9cdd4;
}

// 详情弹窗
.equip-detail-dialog {
  ::v-deep .el-dialog {
    border-radius: 12px;
    overflow: hidden;
  }

  ::v-deep .el-dialog__header {
    padding: 20px 24px;
    border-bottom: 1px solid #f2f3f5;

    .el-dialog__title {
      font-size: 18px;
      font-weight: 600;
      color: #1d2129;
    }
  }

  ::v-deep .el-dialog__body {
    padding: 24px;
  }

  .detail-body {}

  .detail-image {
    border-radius: 8px;
    overflow: hidden;
    margin-bottom: 20px;
    height: 280px;
    background: #f2f3f5;

    img {
      width: 100%;
      height: 100%;
      object-fit: cover;
    }

    .img-placeholder-lg {
      width: 100%;
      height: 100%;
      display: flex;
      align-items: center;
      justify-content: center;
      background: #fef3e8;

      i { font-size: 48px; color: #e67e22; opacity: 0.4; }
    }
  }

  .detail-info {
    margin-bottom: 20px;

    .info-row {
      display: flex;
      padding: 10px 0;
      border-bottom: 1px solid #f2f3f5;

      .label {
        width: 60px;
        flex-shrink: 0;
        font-size: 13px;
        color: #86909c;
      }

      .value {
        flex: 1;
        font-size: 14px;
        color: #1d2129;

        &.price { color: #f56c6c; font-weight: 600; }
        &.in-stock { color: #67c23a; }
        &.out-stock { color: #c9cdd4; }
      }
    }
  }

  .rent-section {
    background: #f7f8fa;
    border-radius: 10px;
    padding: 20px;

    .rent-title {
      font-size: 14px;
      font-weight: 600;
      color: #1d2129;
      margin-bottom: 12px;
    }

    .rent-control {
      display: flex;
      align-items: center;
      gap: 20px;
      margin-bottom: 16px;

      .rent-total {
        font-size: 14px;
        color: #4e5969;

        .total-price {
          font-size: 20px;
          font-weight: 700;
          color: #f56c6c;
        }
      }
    }

    .rent-submit-btn {
      width: 100%;
      height: 44px;
      font-size: 16px;
      font-weight: 600;
      border-radius: 8px;
    }
  }
}
</style>
